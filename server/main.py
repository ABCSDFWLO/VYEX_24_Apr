from enum import Enum
from typing import List
from uuid import uuid4, UUID
from fastapi import Body, Depends, FastAPI, HTTPException, Header, Path, Query
from pydantic import BaseModel, EmailStr, Field
from datetime import datetime
from sqlmodel import Session, and_, col, or_, select
from sqlalchemy.exc import IntegrityError
from passlib.hash import bcrypt
import random
import string
import asyncio

from db import InitialGameSetting, engine, User, Game, Action, GameState, ActionType
from token_manager import TokenManager, user_id_from_token
from verification_mail import send_verification_mail

VERIFICATION_CODE_LENGTH = 6 # TODO : seperate Constants file
VERIFICATION_EXPIRE_TIME = 600 # TODO : seperate Constants file

app = FastAPI()

@app.get(
    "/",
    response_model=str,
    responses={
        200: {
            "description": "Successful Response",
            "content": {
                "application/json": {
                    "examples": {
                        "hello": {
                            "summary": "Hello",
                            "value": "Hello"
                        }
                    }
                }
            }
        }
    }
    )
async def root():
    return "hello"

class UserOut(BaseModel):
    id : int = Field(..., title="User ID", description="The ID of the user", example=1)
    name : str = Field(..., title="User Name", description="The name of the user", example="John Doe")
    email : EmailStr = Field(..., title="User Email", description="The email of the user", example="example@example.com")
    registered_at : datetime = Field(..., title="Registration Date", description="The date the user registered", example=datetime.now())

class UserCreate(BaseModel):
    name : str = Field(..., title="User Name", description="The name of the user", example="John Doe")
    email : EmailStr = Field(..., title="User Email", description="The email of the user", example="exmaple@example.com")
    password : str = Field(..., title="User Password", description="The password of the user", example="password")

class UserLogin(BaseModel):
    email : EmailStr = Field(..., title="User Email", description="The email of the user", example="example@example.com")
    password : str = Field(..., title="User Password", description="The password of the user", example="password")

unverified_users = { UUID:(User,str) }
def generate_verification_code(length:int)->str:
    charset = string.ascii_lowercase + string.digits
    return ''.join(random.choices(charset, k=length))

@app.get("/users",
    response_model=List[UserOut],
    responses = {
        200: {
            "description": "Successful Response",
            "content": {
                "application/json": {
                    "examples": {
                        "users": {
                            "summary": "Users",
                            "value": [
                                {
                                    "id": 1,
                                    "name": "John Doe",
                                    "email": "example@examples.com",
                                    "registered_at": "2021-09-15T12:00:00"
                                },
                                {
                                    "id": 2,
                                    "name": "Jane Doe",
                                    "email": "janedoe@example.com",
                                    "registered_at": "2021-09-15T12:00:00"
                                },
                            ]
                        }
                    }
                }
            }
        },
    }
    )
async def get_users():
    with Session(engine) as session:
        users = session.exec(select(User)).all()
        return [
            UserOut(
                id=user.id,
                name=user.name,
                email=user.email,
                registered_at=user.registered_at
            ) for user in users
        ]

@app.get("/user/{user_name}",
    response_model=UserOut,
    responses = {
        200: {
            "description": "Successful Response",
            "content": {
                "application/json": {
                    "examples": {
                        "user": {
                            "summary": "User",
                            "value": {
                                "id": 1,
                                "name": "John Doe",
                                "email": "example@example.com",
                                "registered_at": "2021-09-15T12:00:00"
                            }
                        }
                    }
                }
            }
        },
        404: {
            "description": "User not found",
            "content": {
                "application/json": {
                    "examples": {
                        "user_not_found": {
                            "summary": "User not found",
                            "value": {
                                "detail": "User not found"
                            }
                        }
                    }
                }
            }
        }
    }
    )
async def get_user(user_name: str):
    with Session(engine) as session:
        result =  session.exec(select(User).where(User.name == user_name)).first()
        if result is None:
            raise HTTPException(status_code=404, detail="User not found")
        return UserOut(
            id=result.id,
            name=result.name,
            email=result.email,
            registered_at=result.registered_at
            )
    
async def expire_verification(uuid:UUID, delay:int=600):
    await asyncio.sleep(delay)
    del unverified_users[uuid]

@app.post("/register", 
    status_code=200,
    response_model=UUID,
    responses={
        200: {
            "description": "Successful registration",
            "content": {
                "application/json": {
                    "examples": {
                        "successful_registration": {
                            "summary": "Successful registration",
                            "value": "123e4567-e89b-12d3-a456-426614174000"
                        }
                    }
                }
            }
        },
        400: {
            "description": "Email or Name already exists",
            "content": {
                "application/json": {
                    "examples": {
                        "email_exists": {
                            "summary": "Email already exists",
                            "value": {
                                "detail": "Email already exists"
                            }
                        },
                        "name_exists": {
                            "summary": "Name already exists",
                            "value": {
                                "detail": "Name already exists"
                            }
                        }
                    }
                }
            }
        }
    }
)
async def create_user(user_create: UserCreate = Body(..., title="User Creation", description="The user to be created")):
    with Session(engine) as session:
        email=session.get(User, user_create.email)
        if email is not None:
            raise HTTPException(status_code=400, detail="Email already exists")
        name=session.get(User, user_create.name)
        if name is not None:
            raise HTTPException(status_code=400, detail="Name already exists")
        user = User(
            name=user_create.name,
            email=user_create.email,
            password_hash=bcrypt.hash(user_create.password),
            registered_at=datetime.now()
        )
        uuid = uuid4()
        unverified_users[uuid] = (user, generate_verification_code(VERIFICATION_CODE_LENGTH))
        asyncio.create_task(expire_verification(uuid,VERIFICATION_EXPIRE_TIME))
        send_verification_mail(unverified_users[uuid][1],user_create.email)
        return uuid
        
@app.post("/verify/{uuid}",
    status_code=201,
    response_model=int,
    responses={
        201: {
            "description": "Successful verification",
            "content": {
                "application/json": {
                    "examples": {
                        "successful_verification": {
                            "summary": "Successful verification",
                            "value": 1
                        }
                    }
                }
            }
        },
        400: {
            "description": "Invalid verification code",
            "content": {
                "application/json": {
                    "examples": {
                        "invalid_verification_code": {
                            "summary": "Invalid verification code",
                            "value": {
                                "detail": "Invalid verification code"
                            }
                        }
                    }
                }
            }
        },
        404: {
            "description": "Invalid User or UUID",
            "content": {
                "application/json": {
                    "examples": {
                        "invalid_user": {
                            "summary": "Invalid User",
                            "value": {
                                "detail": "User not found"
                            }
                        },
                        "invalid_uuid": {
                            "summary": "Invalid UUID",
                            "value": {
                                "detail": "Invalid UUID"
                            }
                        }
                    }
                }
            }
        },
        500: {
            "description": "Database error",
            "content": {
                "application/json": {
                    "examples": {
                        "database_error": {
                            "summary": "Database error",
                            "value": {
                                "detail": "Database error"
                            }
                        }
                    }
                }
            }
        }
    }
    )
async def verify_user(uuid: UUID=Path(...), verify_code: str = Body(..., min_length=6, max_length=6)):
    with Session(engine) as session:
        unverified_user_record = unverified_users.get(uuid) # Tuple, [0]: User, [1]: Verify Code
        if unverified_user_record is None:
            raise HTTPException(status_code=404, detail="Invalid UUID")
        user = unverified_user_record[0]
        if user is None:
            raise HTTPException(status_code=404, detail="User not found")
        if unverified_user_record[1] != verify_code.lower():
            raise HTTPException(status_code=400, detail="Invalid verification code")
        user.registered_at = datetime.now()
        session.add(user)
        try:
            session.commit()
            session.refresh(user)
        except IntegrityError:
            session.rollback()
            raise HTTPException(status_code=500, detail="Database error")
        else:
            del unverified_users[uuid]
            return user.id
        
@app.post("/login",
    status_code=200,
    response_model=List[str],
    responses={
        200: {
            "description": "Successful login",
            "content": {
                "application/json": {
                    "examples": {
                        "successful_login": {
                            "summary": "Successful login",
                            "value": {
                                "access_token": [
                                    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c",
                                    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1Njc4OTAxMjM0IiwibmFtZSI6IkphbmUgRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c",
                                    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI5MDEyMzQ1Njc4IiwibmFtZSI6IkpvbmUgRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c",
                                ],
                            }
                        },
                    }
                }
            }
        },
        400: {
                "description": "Invalid email or password",
                "content": {
                    "application/json": {
                        "examples": {
                            "email_not_found": {
                                "summary": "Email not found",
                                "value": {
                                    "detail": "Email not found"
                                }
                            },
                            "invalid_password": {
                                "summary": "Invalid password",
                                "value": {
                                    "detail": "Invalid password"
                                }
                            }
                        }
                    }
                }
            },
    }
    )
async def login_user(user_login: UserLogin, token_manager:TokenManager =Depends()):
    with Session(engine) as session:
        user = session.exec(select(User).where(User.email == user_login.email)).first()
        if user is None:
            raise HTTPException(status_code=400, detail="Email not found")
        elif not bcrypt.verify(user_login.password, user.password_hash):
            raise HTTPException(status_code=400, detail="Invalid password")
        else:
            return token_manager.generate_token(user.id)
        
@app.post("/logout", status_code=200)
async def logout_user(user_id: int = Depends(user_id_from_token), token_manager:TokenManager=Depends()):
    token_manager.block_token(user_id)

@app.post("/token", status_code=200)
async def refresh_token(token: List[str], token_manager:TokenManager=Depends()):
    user_id = token_manager.verify_token(token)
    with Session(engine) as session:
        user = session.get(User, user_id)
        if user is None:
            raise HTTPException(status_code=400, detail="user not found")
        return token_manager.generate_token(user_id)

class GameOut(BaseModel):
    id : int
    state : GameState
    name : str
    started_at : datetime
    ended_at : datetime | None
    player1 : UserOut | None
    player2 : UserOut | None
    has_password : bool

class GameCreateHostFirst(Enum):
    Host_First = 0
    Host_Last = 1
    Random = 2
    
class GameCreate(BaseModel):
    name : str | None = Field(None, title="Game Name", description="The name of the game", example="New Game")
    password : str | None = Field(None, title="Game Password", description="The password of the game", example="password")
    host_first : GameCreateHostFirst = Field(GameCreateHostFirst.Host_First, title="Host First", description="The player who will make the first move", example="Random")
    board : List[List[int]] | None = Field([], title="Game Board", description="The board of the game")

@app.get("/games", response_model=List[GameOut])
async def get_games(state: List[GameState]|None = Query(default=[GameState.Running], min_length=1, max_length=3), name:str|None = Query(None)):
    with Session(engine) as session:
        if name is None:
            games = session.exec(
                select(Game).where(Game.state.in_(state))
            ).all()
            result = [
                GameOut(
                    id=game.id,
                    state=game.state,
                    name=game.name,
                    started_at=game.started_at,
                    ended_at=game.ended_at,
                    player1=UserOut(
                        id=game.player1.id,
                        name=game.player1.name,
                        email=game.player1.email,
                        registered_at=game.player1.registered_at
                    ) if game.player1_id is not None else None,
                    player2=UserOut(
                        id=game.player2.id,
                        name=game.player2.name,
                        email=game.player2.email,
                        registered_at=game.player2.registered_at
                    ) if game.player2_id is not None else None,
                    has_password=game.password_hash is not None
                ) for game in games
            ]
            return result
        else:
            games = session.exec(
                select(Game).where(
                    and_(
                        col(Game.state).in_(state),
                        or_(
                            col(Game.id).like(f"%{name}%"),
                            col(Game.name).like(f"%{name}%")
                        )
                    )
                )
            ).all()
            result = [
                GameOut(
                    id=game.id,
                    state=game.state,
                    name=game.name,
                    started_at=game.started_at,
                    ended_at=game.ended_at,
                    player1=UserOut(
                        id=game.player1.id,
                        name=game.player1.name,
                        email=game.player1.email,
                        registered_at=game.player1.registered_at
                        ) if game.player1_id is not None else None,
                    player2=UserOut(
                        id=game.player2.id,
                        name=game.player2.name,
                        email=game.player2.email,
                        registered_at=game.player2.registered_at
                    ) if game.player2_id is not None else None,
                    has_password=game.password_hash is not None
                ) for game in games
            ]
            return result

@app.post("/enter_game/{game_id}", status_code=200)
async def enter_game(game_id: int, password:str|None = Body(None), user_id: int = Depends(user_id_from_token)):
    with Session(engine) as session:
        game = session.get(Game, game_id)
        if game is None:
            raise HTTPException(status_code=404, detail="Game not found")
        elif game.state != GameState.Running:
            raise HTTPException(status_code=400, detail="Game Already Ended")
        elif game.player1_id == user_id or game.player2_id == user_id:
            pass
        elif game.player1_id == None:
            if game.password_hash is not None and (password is None or len(password) == 0):
                raise HTTPException(status_code=400, detail="Password Required")
            elif game.password_hash is not None and not bcrypt.verify(password, game.password_hash):
                raise HTTPException(status_code=400, detail="Invalid Password")
            game.player1_id = user_id
        elif game.player2_id == None:
            if game.password_hash is not None and (password is None or len(password) == 0):
                raise HTTPException(status_code=400, detail="Password Required")
            elif game.password_hash is not None and not bcrypt.verify(password, game.password_hash):
                raise HTTPException(status_code=400, detail="Invalid Password")
            game.player2_id = user_id
        else:
            raise HTTPException(status_code=400, detail="Game Full")
        
        session.add(game)
        try:
            session.commit()
            session.refresh(game)
        except IntegrityError:
            session.rollback()
            raise HTTPException(status_code=500, detail="Database error")

@app.post("/create_game", status_code=201, response_model=int)
async def create_game(gameCreate : GameCreate = Body(...), user_id: int = Depends(user_id_from_token)):
    
    name = gameCreate.name
    if name is None or name is not None and len(name) == 0:
        name = "New Game"
    
    password = gameCreate.password
    if password is not None or len(password) == 0:
        password = None
    else :
        password = bcrypt.hash(password)
    
    player1_id = None
    player2_id = None
    if gameCreate.host_first == GameCreateHostFirst.Host_First:
        player1_id = user_id
    elif gameCreate.host_first == GameCreateHostFirst.Host_Last:
        player2_id = user_id
    else:
        if random.choice([True,False]):
            player1_id = user_id
        else:
            player2_id = user_id

    with Session(engine) as session:
        game = Game(
            state=GameState.Running,
            name=name,
            started_at=datetime.now(),
            initial_setting_id=1, # TODO : Change to actual initial setting
            player1_id=player1_id,
            player2_id=player2_id,
            password_hash=bcrypt.hash(password) if password is not None else None
        )
        session.add(game)
        try:
            session.commit()
            session.refresh(game)
        except IntegrityError:
            session.rollback()
            raise HTTPException(status_code=500, detail="Database error")
        return game.id
    
@app.post("/leave_game/{game_id}", status_code=200)
async def leave_game(game_id: int, user_id: int = Depends(user_id_from_token)):
    with Session(engine) as session:
        game = session.get(Game, game_id)
        if game is None:
            raise HTTPException(status_code=404, detail="Game not found")
        elif game.state != GameState.Running:
            raise HTTPException(status_code=400, detail="Game Already Ended")
        elif game.player1_id == user_id:
            game.player1_id = None
        elif game.player2_id == user_id:
            game.player2_id = None
        else:
            raise HTTPException(status_code=400, detail="User not in game")
        session.add(game)
        try:
            session.commit()
            session.refresh(game)
        except IntegrityError:
            session.rollback()
            raise HTTPException(status_code=500, detail="Database error")
        
@app.post("/observe_game/{game_id}", status_code=200)
async def observe_game(game_id: int, user_id: int = Depends(user_id_from_token)):
    with Session(engine) as session:
        game = session.get(Game, game_id)
        if game is None:
            raise HTTPException(status_code=404, detail="Game not found")
        elif game.state != GameState.Running:
            raise HTTPException(status_code=400, detail="Game Already Ended")
        elif game.player1_id != user_id and game.player2_id != user_id:
            raise HTTPException(status_code=400, detail="User not in game")
        else:
            pass

@app.post("/create_initial_game_setting", status_code=201)
async def create_initial_game_setting(user_id: int = Depends(user_id_from_token)):
    with Session(engine) as session:
        initial_game_setting = InitialGameSetting(
            created_by_id=user_id
        )
        session.add(initial_game_setting)
        try:
            session.commit()
            session.refresh(initial_game_setting)
        except IntegrityError:
            session.rollback()
            raise HTTPException(status_code=500, detail="Database error")
from typing import Annotated, List, Tuple, Union
from uuid import uuid4, UUID
from fastapi import Body, Depends, FastAPI, HTTPException, Header, Path, Query
from pydantic import BaseModel, EmailStr
from datetime import datetime
from sqlmodel import Session, col, select
from sqlalchemy.exc import IntegrityError
from passlib.hash import bcrypt
import random
import string
import asyncio

from db import engine, create_db_and_tables, User, Game, Action, GameState, ActionType
from token_manager import get_token_manager, user_id_from_token
from verification_mail import send_verification_mail

app = FastAPI()

@app.get("/", response_model=str)
async def root():
    return "hello"

class UserOut(BaseModel):
    id : int
    name : str
    email : EmailStr
    registered_at : datetime

class UserCreate(BaseModel):
    name : str
    email : EmailStr
    password : str

class UserLogin(BaseModel):
    email : EmailStr
    password : str

unverified_users = { UUID:(User,str) }
def generate_verification_code(length:int)->str:
    charset = string.ascii_lowercase + string.digits
    return ''.join(random.choices(charset, k=length))

@app.get("/users", response_model=List[UserOut])
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

@app.get("/user/{user_name}", response_model=UserOut)
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

@app.post("/register", status_code=200, response_model=UUID)
async def create_user(user_create: UserCreate, code:str=Depends(generate_verification_code), send_mail = Depends(send_verification_mail)):
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
        unverified_users[uuid] = (user, generate_verification_code(6)) # TODO : seperate Constants
        return uuid
        
@app.post("/verify/{uuid}", status_code=201, response_model=int)
async def verify_user(uuid: UUID=Path(...), verify_code: str = Body(len=6)):
    with Session(engine) as session:
        unverified_user_record = unverified_users.get(uuid) # Tuple, [0]: User, [1]: Verify Code
        if unverified_user_record is None:
            raise HTTPException(status_code=404, detail="Invalid UUID")
        user = unverified_user_record[0]
        if user is None:
            raise HTTPException(status_code=404, detail="User not found")
        if unverified_user_record[1] != verify_code:
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
        
@app.post("/login", status_code=200, response_model=List[str])
async def login_user(user_login: UserLogin, token_manager=Depends(get_token_manager)):
    with Session(engine) as session:
        user = session.exec(select(User).where(User.email == user_login.email)).first()
        if user is None:
            raise HTTPException(status_code=400, detail="Email not found")
        elif not bcrypt.verify(user_login.password, user.password_hash):
            raise HTTPException(status_code=400, detail="Invalid password")
        else:
            return token_manager.generate_token(user.id)
        
@app.post("/logout", status_code=200)
async def logout_user(user_id: int = Depends(user_id_from_token), token_manager=Depends(get_token_manager)):
    token_manager.block_token(user_id)

class GameOut(BaseModel):
    id : int
    state : GameState
    started_at : datetime
    ended_at : datetime
    player1_id : int
    player2_id : int
    has_password : bool

@app.get("/games", response_model=List[GameOut])
async def get_games(state: Union[List[GameState],None] = Query(default=[GameState.Running], min_length=1, max_length=3)):
    with Session(engine) as session:
        games = session.exec(select(Game).where(col(Game.state).in_(state))).all()
        result = [
            GameOut(
                id=game.id,
                state=game.state,
                started_at=game.started_at,
                ended_at=game.ended_at,
                player1_id=game.player1_id,
                player2_id=game.player2_id,
                has_password=game.password_hash is not None
            ) for game in games
        ]
        return result

@app.post("/enter_game/{game_id}", status_code=200)
async def enter_game(game_id: int, password:Union[str,None] = Body(...), user_id: int = Depends(user_id_from_token)):
    with Session(engine) as session:
        game = session.get(Game, game_id)
        if game is None:
            raise HTTPException(status_code=404, detail="Game not found")
        elif game.state != GameState.Running:
            raise HTTPException(status_code=400, detail="Game Already Ended")
        elif game.player1_id == None:
            game.player1_id = user_id
        elif game.player2_id == None:
            if game.password_hash is not None and password is None:
                raise HTTPException(status_code=400, detail="Password Required")
            elif game.password_hash != password:
                raise HTTPException(status_code=400, detail="Invalid Password")
            game.player2_id = user_id
        elif game.player1_id == user_id or game.player2_id == user_id:
            pass
        else:
            raise HTTPException(status_code=400, detail="Game Full")
        
        session.add(game)
        try:
            session.commit()
            session.refresh(game)
        except IntegrityError:
            session.rollback()
            raise HTTPException(status_code=500, detail="Database error")
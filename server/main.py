from fastapi import FastAPI, HTTPException
from sqlmodel import SQLModel, Field, create_engine, Session
from pydantic import BaseModel, EmailStr
from enum import Enum
from datetime import datetime
from passlib.hash import bcrypt

app = FastAPI()

class State(Enum):
    Running = "Running"
    P1Win = "P1Win"
    P2Win = "P2Win"

class ActionType(Enum):
    Enter_Game = "Enter_Game"
    Leave_Game = "Leave_Game"
    Surrender = "Surrender"
    Move = "Move"
    Build = "Build"
    Demolish = "Demolish"
    Return_After_Demolish = "Return_After_Demolish"
    Win_Slay = "Win_Slay"
    Win_Climb_Top = "Win_Climb_Top"
    Win_Lock = "Win_Lock"
    End_Turn = "End_Turn"
    Undo = "Undo"
    Redo = "Redo"
    Settle = "Settle"

class User(SQLModel, table=True):
    id: int = Field(primary_key=True)
    name: str = Field(index=True,unique=True)
    email: EmailStr = Field(index=True,unique=True)
    password_hash: str
    registered_at: datetime
class Game(SQLModel, table=True):
    id: int = Field(primary_key=True)
    state: State
    started_at: datetime
    ended_at: datetime
    player1_id: int = Field(foreign_key="user.id")
    player2_id: int = Field(foreign_key="user.id")
    password: str
class Action(SQLModel, table=True):
    id: int = Field(primary_key=True)
    game_id: int = Field(foreign_key="game.id")
    player_id: int = Field(foreign_key="user.id")
    index: int
    timestamp: datetime
    type: ActionType
    data: str
    
sqlite_filename = "database.db"
sqlite_url = f"sqlite:///{sqlite_filename}"
engine = create_engine(sqlite_url, echo=True)

@app.get("/")
async def root() -> str:
    return "hello"

@app.get("/user/{user_id}")
async def get_user(user_id: int) -> User:
    with Session(engine) as session:
        user = session.get(User, user_id)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        return user
    
@app.get("/user/{user_name}")
async def get_user(user_name: str) -> User:
    with Session(engine) as session:
        user = session.get(User, user_name)
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        return user

class UserCreate(BaseModel):
    name: str
    email: EmailStr
    password: str = Field(min_length=8, max_length=32)

@app.post("/register")
async def create_user(user: UserCreate) -> User:
    user = User(
        name=user.name,
        email=user.email,
        password_hash=bcrypt.hash(user.password),
        registered_at=datetime.now()
        )
    with Session(engine) as session:
        session.add(user)
        session.commit()
        session.refresh(user)
        return user
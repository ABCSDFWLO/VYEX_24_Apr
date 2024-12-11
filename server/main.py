from fastapi import FastAPI
from sqlmodel import SQLModel, Field, create_engine
from enum import Enum
from datetime import datetime

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
    name: str = Field(unique=True)
    email: str = Field(unique=True)
    password: str
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
    with engine.connect() as connection:
        user = connection.get(User, user_id)
        return user
    
@app.get("/user/{user_name}")
async def get_user(user_name: str) -> User:
    with engine.connect() as connection:
        user = connection.get(User, user_name)
        return user
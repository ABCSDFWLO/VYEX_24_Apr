from sqlmodel import SQLModel, Field, create_engine
from pydantic import EmailStr
from datetime import datetime
from enum import Enum


class GameState(Enum):
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
    state: GameState
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
    
sqlite_file_name = "database.db"
sqlite_url = f"sqlite:///{sqlite_file_name}"
engine = create_engine(sqlite_url, echo=True)

def create_db_and_tables():
    SQLModel.metadata.create_all(engine)

if __name__ == "__main__":
    create_db_and_tables()
from typing import Union
from sqlmodel import Relationship, SQLModel, Field, create_engine
from sqlalchemy.orm import relationship
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
    Draw_Suggest = "Draw_Suggest"
    Draw_Accept = "Draw_Accept"
    Draw_Reject = "Draw_Reject"
    Move = "Move"
    Xaht = "Xaht"
    Vusu = "Vusu"
    Win_Yzav = "Win_Yzav"
    Lose_Makk = "Lose_Makk"
    Undo = "Undo"
    Chuwm_Xaht = "Chuwm_Xaht"

class User(SQLModel, table=True):
    id: int = Field(primary_key=True)
    name: str = Field(index=True,unique=True)
    email: EmailStr = Field(index=True,unique=True)
    password_hash: str
    registered_at: datetime

    games_as_player1: list["Game"] = Relationship(back_populates="player1", sa_relationship=relationship("Game", foreign_keys="[Game.player1_id]"))
    games_as_player2: list["Game"] = Relationship(back_populates="player2", sa_relationship=relationship("Game", foreign_keys="[Game.player2_id]"))
    actions: list["Action"] = Relationship(back_populates="player")
class Game(SQLModel, table=True):
    id: int = Field(primary_key=True)
    state: GameState
    name: str
    started_at: datetime
    ended_at: datetime | None
    player1_id: int | None = Field(foreign_key="user.id")
    player2_id: int | None = Field(foreign_key="user.id")
    password_hash: str | None

    player1: User = Relationship(back_populates="games_as_player1", sa_relationship=relationship("User", foreign_keys="[Game.player1_id]"))
    player2: User | None = Relationship(back_populates="games_as_player2", sa_relationship=relationship("User", foreign_keys="[Game.player2_id]"))
    actions: list["Action"] = Relationship(back_populates="game")
class Action(SQLModel, table=True):
    id: int = Field(primary_key=True)
    game_id: int = Field(foreign_key="game.id")
    player_id: int = Field(foreign_key="user.id")
    index: int
    timestamp: datetime
    type: ActionType
    data: str

    game: Game = Relationship(back_populates="actions")
    player: User = Relationship(back_populates="actions")
    
sqlite_file_name = "database.db"
sqlite_url = f"sqlite:///{sqlite_file_name}"
engine = create_engine(sqlite_url, echo=True)

def create_db_and_tables():
    SQLModel.metadata.create_all(engine)

if __name__ == "__main__":
    create_db_and_tables()
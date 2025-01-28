from typing import Union
from sqlmodel import Relationship, SQLModel, Field, create_engine
from sqlalchemy.orm import relationship
from pydantic import EmailStr
from datetime import datetime
from enum import Enum

default_pann_code = b'\x41\x01\x21\x01\x01\x00\x00\x01\x31\x01\x01\x01\x01\x00\x21\x01\x11\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x51\x01\x61\x00\x01\x01\x01\x01\x71\x01\x00\x00\x01\x01\x61\x01\x81'

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
    Chuwm_Xaht = "Chuwm_Xaht"

class User(SQLModel, table=True):
    id: int = Field(primary_key=True)
    name: str = Field(index=True,unique=True)
    email: EmailStr = Field(index=True,unique=True)
    password_hash: str
    registered_at: datetime

    initial_game_settings: list["InitialGameSetting"] = Relationship(back_populates="created_by")
    games_as_player1: list["Game"] = Relationship(back_populates="player1", sa_relationship=relationship("Game", foreign_keys="[Game.player1_id]"))
    games_as_player2: list["Game"] = Relationship(back_populates="player2", sa_relationship=relationship("Game", foreign_keys="[Game.player2_id]"))
    actions: list["Action"] = Relationship(back_populates="player")
class InitialGameSetting(SQLModel, table=True):
    __tablename__ = "initial_game_setting"

    id: int = Field(primary_key=True)
    created_at: datetime = Field(default_factory=datetime.now)
    created_by_id: int = Field(foreign_key="user.id")
    pann_size_x: int = Field(default=7, ge=2, le=64)
    pann_size_y: int = Field(default=7, ge=2, le=64)
    pann_code: bytes = Field(default=default_pann_code)
    """
    byteStream of the pann.
    Each byte represents a cell in the pann.
    LSB[0~3] : wall (0~15 heights)
    LSB[4~7] : maal (0b0000 : No Maal, 0b0001 : XAHT_BLUE, 0b0010 : VUSU_BLUE, 0b0011 : EWNG_BLUE, 0b0100 : YZAV_BLUE, 0b0101 : XAHT_RED, 0b0110 : VUSU_RED, 0b0111 : EWNG_RED, 0b1000 : YZAV_RED)
    ex) 0b00000000 : empty cell, 0b01010011 : XAHT_RED on the 3-height wall
    """
    chuwm_order_reverse: bool = Field(default=False)
    chuwm_p1: bytes = Field(default=b'\x04\x06')
    chuwm_p2: bytes = Field(default=b'\x08')
    action_point_max: int = Field(default=3, ge=1, le=32)
    action_point_advantage_for_p1: int = Field(default=0, ge=-32, le=32)
    action_point_advantage_for_p2: int = Field(default=1, ge=-32, le=32)

    created_by: User = Relationship(back_populates="initial_game_settings")
    games: list["Game"] = Relationship(back_populates="initial_setting")
class Game(SQLModel, table=True):
    id: int = Field(primary_key=True)
    state: GameState
    name: str
    started_at: datetime
    ended_at: datetime | None
    initial_setting_id: int = Field(foreign_key="initial_game_setting.id")
    player1_id: int | None = Field(foreign_key="user.id")
    player2_id: int | None = Field(foreign_key="user.id")
    password_hash: str | None

    initial_setting: InitialGameSetting = Relationship(back_populates="games")
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
    maal_coord_x: int | None
    maal_coord_y: int | None
    action_coord_x: int | None
    action_coord_y: int | None

    game: Game = Relationship(back_populates="actions")
    player: User = Relationship(back_populates="actions")

sqlite_file_name = "database.db"
sqlite_url = f"sqlite:///{sqlite_file_name}"
engine = create_engine(sqlite_url, echo=True)

def create_db_and_tables():
    SQLModel.metadata.create_all(engine)

if __name__ == "__main__":
    create_db_and_tables()
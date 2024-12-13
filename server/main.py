from typing import List, Union
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, EmailStr
from datetime import datetime
from sqlmodel import Session, select

from db import engine, create_db_and_tables, User, Game, Action, State, ActionType

app = FastAPI()

@app.get("/")
async def root() -> str:
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

@app.get("/user/{user_id}", response_model=UserOut)
async def get_user(user_id: Union[int, str]):
    with Session(engine) as session:
        if user_id is str:
            result =  session.exec(select(User).where(User.name == user_id)).first()
            if result is None:
                raise HTTPException(status_code=404, detail="User not found")
            return UserOut(
                id=result.id,
                name=result.name,
                email=result.email,
                registered_at=result.registered_at
                )
        else:
            result = session.exec(select(User).where(User.id == user_id)).first()
            if result is None: 
                raise HTTPException(status_code=404, detail="User not found")
            return UserOut(
                id=result.id,
                name=result.name,
                email=result.email,
                registered_at=result.registered_at
                )

@app.post("/register", status_code=201, response_model=int)
async def create_user(user_create: UserCreate):
    with Session(engine) as session:
        user = User(
            name=user_create.name,
            email=user_create.email,
            password_hash=user_create.password,
            registered_at=datetime.now()
        )
        print(user)
        session.add(user)
        print(user)
        session.commit()
        session.refresh(user)
        print(user)
        return user.id
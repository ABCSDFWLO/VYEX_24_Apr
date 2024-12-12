from fastapi import FastAPI
from pydantic import BaseModel, EmailStr

from db import SQLModel, Field

app = FastAPI()

@app.get("/")
async def root() -> str:
    return "hello"

@app.get("/user/{user_id}")
async def get_user(user_id: int):
    pass
    
@app.get("/user/{user_name}")
async def get_user(user_name: str):
    pass

class UserCreate(BaseModel):
    name: str
    email: EmailStr
    password: str = Field(min_length=8, max_length=32)

@app.post("/register")
async def create_user(user_create: UserCreate):
    pass
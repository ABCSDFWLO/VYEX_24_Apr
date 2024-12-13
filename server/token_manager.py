from fastapi import Depends, HTTPException, Header
import jwt
import threading
import random
import threading
import time
from typing import List
import jwt

class TokenManager:
    """
    A class to manage tokens for user authentication.
    Using 3 random codes to encode the user_id in the token.
    """
    _instance = None
    TOKEN_EXPIRATION_TIME = 15 # 60 * 60
    RANDOM_CODE_REFRESH_INTERVAL = 15 # 60 * 60 * 3
    TOKEN_COUNT = 3
    KEY = "user_id"

    def __new__(cls, *args, **kwargs):
        if not cls._instance:
            cls._instance = super(TokenManager, cls).__new__(cls, *args, **kwargs)
        return cls._instance

    def __init__(self):
        if not hasattr(self, "random_codes"):
            self.random_codes = [str(random.random()) for _ in range(TokenManager.TOKEN_COUNT)]
            self.blocked_tokens = []
            self._start_refresh_timer()

    def generate_token(self, user_id: int) -> List[str]:
        payload = {TokenManager.KEY: user_id}
        return [jwt.encode(payload, code, algorithm="HS256") for code in self.random_codes]

    def verify_token(self, token: List[str]) -> int:
        """Verify the token and return the user_id."""
        if len(token) != TokenManager.TOKEN_COUNT:
            raise ValueError("Invalid token count : "+str(len(token)))
        correct = 0
        user_id = None
        for code in self.random_codes:
            for t in token:
                try:
                    decoded_user_id = jwt.decode(t, code, algorithms=["HS256"])[TokenManager.KEY]
                    if user_id is None:
                        user_id = decoded_user_id
                    elif self.blocked_tokens and user_id in [t[0] for t in self.blocked_tokens]:
                        raise ValueError("Token is blocked : "+str(user_id))
                    elif user_id != decoded_user_id:
                        raise ValueError("Token user_id mismatch : "+str(user_id)+" != "+str(decoded_user_id))
                    correct += 1
                except jwt.InvalidTokenError:
                    pass
        if correct >= TokenManager.TOKEN_COUNT - 1:
            return user_id
        raise ValueError("Not enough valid tokens : "+str(correct))
    
    def block_token(self, user_id: int):
        """Block a token for a user."""
        self.blocked_tokens.append((user_id, time.time() + TokenManager.TOKEN_EXPIRATION_TIME))

    def _refresh_random_codes(self):
        """Replace the oldest random code with a new one."""
        self.random_codes = [self.random_codes[1], self.random_codes[2], str(random.random())]

    def _refresh_blocked_tokens(self):
        """Remove blocked tokens that have expired."""
        now = time.time()
        self.blocked_tokens = [t for t in self.blocked_tokens if t[1] > now]

    def _start_refresh_timer(self):
        """Start a background thread to refresh random codes and blocked tokens."""
        def refresh():
            while True:
                self._refresh_random_codes()
                self._refresh_blocked_tokens()
                print("Refreshed random codes and blocked tokens.")
                print(f"Random codes: {self.random_codes}")
                print(f"Blocked tokens: {self.blocked_tokens}")
                time.sleep(TokenManager.RANDOM_CODE_REFRESH_INTERVAL)
        refresh_thread = threading.Thread(target=refresh, daemon=True)
        refresh_thread.start()

def get_token_manager():
    """
    Get the token manager singleton instance.
    
    Returns:
        TokenManager : The token manager singleton.
    """
    return TokenManager()

def user_id_from_token(token1: str = Header(...), token2: str = Header(...), token3: str = Header(...), token_manager: TokenManager = Depends(get_token_manager)) -> int:
    """
    Get the user_id from 3 token Headers.

    Parameters:
        token1 (str) : The first token.
        token2 (str) : The second token.
        token3 (str) : The third token.
        token_manager (TokenManager) : The token manager singleton.

    Returns:
        int : The user_id.
    """
    try:
        token_list = [token1, token2, token3]
        user_id = token_manager.verify_token(token_list)
    except ValueError as e:
        print(e)
        raise HTTPException(status_code=401, detail="Invalid token")
    else:
        return user_id
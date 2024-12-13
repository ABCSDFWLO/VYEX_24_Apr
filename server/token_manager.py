import jwt
import threading
import random
import threading
import time
from typing import List
import jwt

def get_token_manager():
    return TokenManager()

class TokenManager:
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
        correct = 0
        user_id = None
        for code in self.random_codes:
            for t in token:
                try:
                    decoded_user_id = jwt.decode(t, code, algorithms=["HS256"])[TokenManager.KEY]
                    if user_id is None:
                        user_id = decoded_user_id
                    elif self.blocked_tokens and user_id in [t[0] for t in self.blocked_tokens]:
                        raise ValueError("Token is blocked.")
                    elif user_id != decoded_user_id:
                        raise ValueError("Token user_id mismatch.")
                    correct += 1
                except jwt.InvalidTokenError:
                    pass
        if correct >= TokenManager.TOKEN_COUNT - 1:
            return user_id
        raise ValueError("Not enough valid tokens.")
    
    def block_token(self, user_id: int):
        self.blocked_tokens.append((user_id, time.time() + TokenManager.TOKEN_EXPIRATION_TIME))

    def _refresh_random_codes(self):
        """Replace the oldest random code with a new one."""
        self.random_codes = [self.random_codes[1], self.random_codes[2], str(random.random())]

    def _refresh_blocked_tokens(self):
        """Remove blocked tokens that have expired."""
        now = time.time()
        self.blocked_tokens = [t for t in self.blocked_tokens if t[1] > now]

    def _start_refresh_timer(self):
        """Start a background thread to refresh random codes periodically."""
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

get_token_manager()
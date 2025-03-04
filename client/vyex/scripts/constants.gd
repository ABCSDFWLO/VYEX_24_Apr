extends Node

const HOST := "127.0.0.1"
const PORT_WITH_COLON := ":8000"
const LOGIN_URL := "/login"
const REGISTER_URL := "/register"
const TOKEN_URL := "/token"
const REGISTER_VERIFY_URL := "/verify"
const GAMES_URL := "/games"
const CREATE_GAME_URL := "/create_game"
const ENTER_GAME_URL := "/enter_game"


const MOVE_ACC := 1.0
const ROT_ACC := 0.2

const MOVE_SPD_MAX := 10.0
const ROT_SPD_MAX := 2.0

const MOVE_SPD_EPS := 1.1
const ROT_SPD_EPS := 0.21

const ROT_DIR_MAX := 0.99

const MOUSE_MOVE_SPD := 0.3
const MOUSE_WHEEL_UNIT := 30

const TOP_VIEW_ANIMATION_DURATION := 0.5
const TOP_VIEW_CAMERA_EULER_ANGLE := Vector3(-PI*0.499,0,0) #0.5 freezes the move
const TOP_VIEW_CAMERA_POSITION := Vector3.UP*20

const RAY_LENGTH := 4000

const KANN_WIDTH := 2.5
const KANN_HEIGHT := 1.5
const KANN_MARGIN := 0.25

enum Maal {
	XAHT_BLUE=16, VUSU_BLUE=32, EWNG_BLUE=48, YZAV_BLUE=64,
	XAHT_RED=80, VUSU_RED=96, EWNG_RED=112, YZAV_RED=128,
	NONE=0,
}

package main

import (
	"vyex_server/internal"
	"vyex_server/internal/logger"

	"go.uber.org/zap"
)

func main() {
	logger.InitLogger(internal.LogFileName, 10, 5, 30, true)
	defer logger.CloseLogger()

	logger.L().Info("🚀 server started", zap.String("version", internal.AppVersion))
}

package logger

import (
	"os"
	"path/filepath"
	"sync"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
	"gopkg.in/natefinch/lumberjack.v2"
)

var (
	log  *zap.Logger
	once sync.Once
)

func InitLogger(logFile string, maxSize, maxBackups, maxAge int, compress bool) {
	once.Do(func() {
		// validate parameters
		if maxSize <= 0 {
			maxSize = 10 // default to 10 MB
		}
		if maxBackups <= 0 {
			maxBackups = 5 // default to 5 backups
		}
		if maxAge <= 0 {
			maxAge = 30 // default to 30 days
		}
		if logFile == "" {
			logFile = "app.log" // default log file name
		}

		// if log directory does not exist, create it
		if err := os.MkdirAll(filepath.Dir(logFile), 0755); err != nil {
			panic("failed to create log directory: " + err.Error())
		}

		// Configure lumberjack for log rotation
		writer := &lumberjack.Logger{
			Filename:   logFile,
			MaxSize:    maxSize,    // megabytes
			MaxBackups: maxBackups, // number of backups
			MaxAge:     maxAge,     // days
			Compress:   compress,   // compress old logs
		}

		// Create a zap core with the lumberjack writer
		core := zapcore.NewCore(
			zapcore.NewJSONEncoder(zap.NewProductionEncoderConfig()),
			zapcore.AddSync(writer),
			zap.InfoLevel,
		)

		log = zap.New(core, zap.AddCaller())
	})
}

func L() *zap.Logger {
	if log == nil {
		panic("logger not initialized, call InitLogger first")
	}
	return log
}

func CloseLogger() {
	if log != nil {
		_ = log.Sync() // Ensure all logs are flushed
	}
}

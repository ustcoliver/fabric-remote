# 设置logger
import logging
import logging.handlers
import sys
import colorlog

# 创建日志记录器
logger = logging.getLogger("remote-logger")
logger.setLevel(logging.DEBUG)

# 创建文件处理器
debug_file_handler = logging.handlers.RotatingFileHandler(
    "logs/debug.log", mode="a", maxBytes=1000000000, backupCount=5
)
info_file_handler = logging.handlers.RotatingFileHandler(
    "logs/info.log", mode="a", maxBytes=1000000000, backupCount=5
)

# 创建控制台处理器
console_handler = colorlog.StreamHandler(sys.stdout)

# 分别为三种handler创建formatter
info_formatter = logging.Formatter(
    "[%(asctime)s] - [%(levelname)s] - %(message)s", "%Y-%m-%d %H:%M:%S"
)
debug_formatter = logging.Formatter(
    "[%(asctime)s] - [%(levelname)s] - [%(funcName)s.%(filename)s.%(lineno)d] - %(message)s",
    "%Y-%m-%d %H:%M:%S",
)
console_formatter = colorlog.ColoredFormatter(
    "%(log_color)s [%(levelname)s] %(blue)s%(message)s %(reset)s",
    datefmt=None,
    reset=True,
    log_colors={
        "DEBUG": "cyan",
        "INFO": "green",
        "WARNING": "yellow",
        "ERROR": "red",
        "CRITICAL": "red,bg_white",
    },
    secondary_log_colors={},
    style="%",
)


# 设置处理器的日志级别和格式化器
debug_file_handler.setLevel(logging.DEBUG)
debug_file_handler.setFormatter(debug_formatter)

info_file_handler.setLevel(logging.INFO)
info_file_handler.setFormatter(info_formatter)

console_handler.setLevel(logging.INFO)
console_handler.setFormatter(console_formatter)

# 将处理器添加到日志记录器
logger.addHandler(debug_file_handler)
logger.addHandler(info_file_handler)
logger.addHandler(console_handler)


def clear_log(log_file):
    logger.debug(f"clear logs/{log_file}")
    with open("logs/" + log_file, "w") as f:
        f.write("")


def clear_logs():
    clear_log("debug.log")
    clear_log("info.log")
    clear_log("sync.log")

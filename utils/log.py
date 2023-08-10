import datetime
import os
import logging
import colorlog
from logging.handlers import RotatingFileHandler
# 创建日志对象
logger = logging.getLogger('mylogger')
logger.setLevel(logging.DEBUG)

# 创建控制台日志对象
console_handler = logging.StreamHandler()
console_handler.setLevel(logging.INFO)

# 设置控制台日志格式
formatter = colorlog.ColoredFormatter(
    '%(log_color)s%(asctime)s - %(levelname)s [%(funcName)s] %(message)s%(reset)s',
    datefmt='%Y-%m-%d %H:%M:%S',
    log_colors={
        'DEBUG': 'cyan',
        'INFO': 'blue',
        'WARNING': 'yellow',
        'ERROR': 'red',
        'CRITICAL': 'red,bg_white',
    }
)
console_handler.setFormatter(formatter)

# 设置日志文件和相关格式
log_folder = 'logs'
if not os.path.exists(log_folder):
    os.makedirs(log_folder)

current_time = datetime.datetime.now().strftime('%Y-%m-%d_%H')
log_file = os.path.join(log_folder, f'{current_time}.log')
file_handler = RotatingFileHandler(filename=log_file, maxBytes=1024 * 1024 * 5, backupCount=3)
file_handler.setLevel(logging.DEBUG)
file_handler.setFormatter(
    logging.Formatter('%(asctime)s [%(filename)s:%(''lineno)d]-[%(funcName)s] %(levelname)s : %(message)s'))

# 添加handler
logger.addHandler(console_handler)
logger.addHandler(file_handler)

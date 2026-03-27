.PHONY: all setup start test package clean

all: setup test

setup:
	@echo "检查依赖..."
	./setup.sh

start:
	@echo "启动 CDDA..."
	./start.sh

test:
	@echo "测试 tmux 连接..."
	@tmux has-session -t cdda-text 2>/dev/null && echo "[OK] cdda-text session exists" || echo "[INFO] cdda-text session 不存在 (正常)"

tools:
	@echo "可用工具命令 (需要先启动游戏):"
	@./scripts/cdda-tools.sh

package:
	./package.sh

clean:
	rm -rf dist/
	rm -rf runs/

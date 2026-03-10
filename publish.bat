@echo off
:: 设置字符集防止中文乱码
chcp 65001

:: 1. 检查是否输入了更新备注
set /p MSG="请输入本次更新的备注（比如：发布新照片）: "
if "%MSG%"=="" (
  echo 错误：必须输入更新备注！
  pause
  exit /b 1
)

:: 2. 构建网站
echo [1/3] 正在构建网站（本地编译）...
hugo --minify

:: 3. 推送成品到 GitHub Pages 仓库
echo [2/3] 正在推送到成品仓库 (RemyWang22.github.io)...
cd public
git add .
git commit -m "%MSG%"
git push -f origin main

:: 4. 推送源码到备份仓库
echo [3/3] 正在备份源码到 remy-blog...
cd ..
git add .
git commit -m "%MSG%"
git push origin main

echo ====================================
echo ✅ 部署完成！
echo 网址：https://remywang22.github.io/
echo ====================================
pause

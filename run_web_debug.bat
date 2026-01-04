@echo off
echo 正在启动调试模式 (已禁用浏览器安全检查以允许 API 跨域调用)...
flutter run -d chrome --web-browser-flag "--disable-web-security"
pause
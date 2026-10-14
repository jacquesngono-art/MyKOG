import paramiko, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

c = paramiko.SSHClient()
c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
c.connect("185.98.128.123", username="root", password="vfZeEJTY5Fz", timeout=15, allow_agent=False, look_for_keys=False)
sftp = c.open_sftp()
sftp.put(r"C:\Users\athar\Desktop\fredy\MyKOG-Terminal\MyKOG-Terminal\backend-API\controllers\userController.js",
         "/opt/mykog-api/controllers/userController.js")
sftp.close()
print("PUT userController.js")
stdin, stdout, stderr = c.exec_command("pm2 restart mykog-api --update-env 2>&1 | tail -2 && sleep 4", timeout=90)
print(stdout.read().decode("utf-8", "replace"))
c.close()

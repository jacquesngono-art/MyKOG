import paramiko, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

c = paramiko.SSHClient()
c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
c.connect("185.98.128.123", username="root", password="vfZeEJTY5Fz", timeout=15, allow_agent=False, look_for_keys=False)
sftp = c.open_sftp()
sftp.put(r"C:\Users\athar\Desktop\fredy\MyKOG-Terminal\MyKOG-Terminal\migrate_urls.js", "/opt/mykog-api/migrate_urls.js")
sftp.close()
stdin, stdout, stderr = c.exec_command("cd /opt/mykog-api && node migrate_urls.js", timeout=120)
print(stdout.read().decode("utf-8", "replace"))
err = stderr.read().decode("utf-8", "replace")
if err: print("STDERR:", err[:1500])
c.close()

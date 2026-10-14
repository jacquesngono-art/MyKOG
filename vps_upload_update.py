import paramiko, sys, io, os
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

DIST = r"C:\Users\athar\Desktop\fredy\MyKOG-Terminal\MyKOG-Terminal\desktop-app\dist"
EXE = "MyKOG-Setup-1.1.0-x64.exe"

c = paramiko.SSHClient()
c.set_missing_host_key_policy(paramiko.AutoAddPolicy())
c.connect("185.98.128.123", username="root", password="vfZeEJTY5Fz", timeout=15, allow_agent=False, look_for_keys=False)
sftp = c.open_sftp()

files = [
    (os.path.join(DIST, "latest.yml"),                 "/opt/mykog-api/public/updates/latest.yml"),
    (os.path.join(DIST, EXE),                          "/opt/mykog-api/public/updates/" + EXE),
    (os.path.join(DIST, EXE + ".blockmap"),            "/opt/mykog-api/public/updates/" + EXE + ".blockmap"),
    (os.path.join(DIST, EXE),                          "/opt/mykog-api/public/downloads/" + EXE),
]
for local, remote in files:
    print("PUT", remote, f"({os.path.getsize(local)//1024//1024} Mo)", flush=True)
    sftp.put(local, remote)

sftp.close()
stdin, stdout, stderr = c.exec_command("ls -la /opt/mykog-api/public/updates/ && curl -s -o /dev/null -w 'latest.yml: %{http_code}\n' https://vps123057.serveur-vps.net/mykog-api/updates/latest.yml", timeout=60)
print(stdout.read().decode("utf-8", "replace"))
c.close()

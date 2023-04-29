import urllib.request

page = urllib.request.urlopen("https://ballistica.net/downloads")

page=page.read().decode("utf-8").split("<a")
a_tags=[]
links=[]

for i in page:
    a_tags.append(i.split(">")[0])

for i in a_tags:
    if i.strip().startswith("href="):
        links.append(i.strip()[5:])

linux_arm_links=[]
for i in links:
    if "Linux_Arm64".lower() in i.lower():
        linux_arm_links.append(i)

for i in linux_arm_links:
    if "server" in i.lower():
        print(i)

local moon = require("moon")
local socket = require("moon.socket")

---@type gate_context
local context = ...

local listenfd

local CMD = {}

function CMD.Init()
    context.addr_auth = moon.queryservice("auth")
    return true
end

function CMD.Start()
    ---开始接收客户端网络链接
    listenfd  = socket.listen(context.conf.host, context.conf.port, moon.PTYPE_SOCKET)
    assert(listenfd>0,"server listen failed")
    socket.start(listenfd)
    print("GAME Server Start Listen",context.conf.host, context.conf.port)
    return true
end

function CMD.Shutdown()
    for _, c in pairs(context.uid_map) do
        socket.close(c.fd)
    end
    if listenfd then
        socket.close(listenfd)
    end
    moon.quit()
    return true
end

function CMD.Kick(uid)
    local c = context.uid_map[uid]
    print("gate kick", uid)
	if c then
        socket.close(c.fd)
    end
    return true
end

function CMD.KickByFd(fd)
    print("gate KickByFd", fd)
    socket.close(fd)
    return true
end

function CMD.SetFdUid(req)
    if context.auth_watch[req.fd] ~= req.sign then
        return false, "client closed before auth done!"
    end
    local old = context.uid_map[req.uid]
    if old and old.fd ~= req.fd then
        context.fd_map[old.fd] = nil
        socket.close(old.fd)
        print("kick user", req.uid, "oldfd", old.fd, "newfd", req.fd)
    end

    local c = {
        uid = req.uid,
        fd = req.fd,
        addr_user = req.addr_user
    }

    context.fd_map[req.fd] = c
    context.uid_map[req.uid] = c
    context.auth_watch[req.fd] = nil
    print(string.format("SetFdUid %d %d %08X", req.fd, req.uid,  req.addr_user))
    return true
end

return CMD
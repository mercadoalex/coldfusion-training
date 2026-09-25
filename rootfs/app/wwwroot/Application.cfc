component {

    this.name              = "CFTraining";
    this.sessionManagement = true;
    this.sessionTimeout    = createTimeSpan(0, 0, 30, 0);  // 30 minutes

    // WebSocket channels — required by the WebSockets lesson (module 3)
    this.wschannels = [
        { name="chat", cfclistener="WSHandler" }
    ];

    public boolean function onApplicationStart() {
        application.startTime = now();
        writeLog(text="Application started at #now()#", file="application");
        return true;
    }

    public boolean function onSessionStart() {
        session.userId = 0;
        return true;
    }

    public boolean function onRequestStart(string targetPage) {
        var publicPages = ["/login.cfm", "/register.cfm"];
        if (!session.userId && !arrayFind(publicPages, arguments.targetPage)) {
            location(url="/login.cfm", addtoken=false);
            return false;  // abort the request — page will not execute
        }
        return true;
    }

    public void function onError(any exception, string eventName) {
        writeOutput("An error occurred: #exception.message#");
    }

}

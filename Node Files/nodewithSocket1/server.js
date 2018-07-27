var express = require("express")
var mongoose = require("mongoose")
var bodyParser = require("body-parser")

var app = express()
var http = require("http").Server(app)
var io = require("socket.io")(http)

var conString = "mongodb://user1:user123@ds229621.mlab.com:29621/socketchatdb"
//var conString = "mongodb://localhost:27017/mylearning";
app.use(express.static(__dirname))
app.use(bodyParser.json())
//app.use(bodyParser.urlencoded({ extended: false }))
app.use(bodyParser.urlencoded({ extended: true }));


var server = http.listen(3020, () => {
    console.log("Well done, now I am listening on ", server.address().port)
})

mongoose.connect(conString, function(err){
    if(err){
        console.log(err);
    } else
    {
        console.log('Connected to DB');
    }
});

var chatSchema = mongoose.Schema({
    nickname:String,
    msg:String,
    date: {type: Date, default: Date.now}
});

var Chat = mongoose.model('Message',chatSchema);

app.get('/', function(req, res){
    res.send(_dirname + '/index.html');
  });

io.on("connection", (socket) => {
    console.log("Socket is connected...")
})

var userList = [];
var typingUsers = {};

io.on('connection', function(clientSocket){
  console.log('a user connected');

  clientSocket.on('chatMessage', function(nickname,message){

    //Saving data in mongo DB here...
    // var newMsg = new Chat({nickname: '' + nickname,msg: '' + message});

    // console.log('saving newMsg: ' + newMsg);

    // newMsg.save(function(err){
    //     console.log('saved, err = ' + err);
    //     if(err) throw err;
    //     console.log('echoeing back data =' + newMsg);
        //io.sockets.emit('newChatMessage', newMsg);
    //});

 });

  clientSocket.on('disconnect', function(){
    console.log('user disconnected');

    var clientNickname;
    for (var i=0; i<userList.length; i++) {
      if (userList[i]["id"] == clientSocket.id) {
        userList[i]["isConnected"] = false;
        clientNickname = userList[i]["nickname"];
        break;
      }
    }

    delete typingUsers[clientNickname];
    io.emit("userList", userList);
    //io.emit("userExitUpdate", clientNickname);
    io.emit("userTypingUpdate", typingUsers);
  });


  clientSocket.on("exitUser", function(clientNickname){
    for (var i=0; i<userList.length; i++) {
      if (userList[i]["id"] == clientSocket.id) {
        userList.splice(i, 1);
        break;
      }
    }
    delete clientNickname;
    var message = "User " + clientNickname + " was deleted";
    console.log(message);
    io.emit("userExitUpdate", clientNickname);
  });


  clientSocket.on('chatMessage', function(clientNickname, message){
    var currentDateTime = new Date().toLocaleString();
    delete typingUsers[clientNickname];
    io.emit("userTypingUpdate", typingUsers);
    io.emit('newChatMessage', clientNickname, message, currentDateTime);
  });


  clientSocket.on("connectUser", function(clientNickname) {
      var message = "User " + clientNickname + " was connected.";
      console.log(message);

      var userInfo = {};
      var foundUser = false;
      for (var i=0; i<userList.length; i++) {
        if (userList[i]["nickname"] == clientNickname) {
          userList[i]["isConnected"] = true
          userList[i]["id"] = clientSocket.id;
          userInfo = userList[i];
          foundUser = true;
          break;
        }
      }

      if (!foundUser) {
        userInfo["id"] = clientSocket.id;
        userInfo["nickname"] = clientNickname;
        userInfo["isConnected"] = true
        userList.push(userInfo);
      }

      io.emit("userList", userList);
      io.emit("userConnectUpdate", userInfo)
  });


  clientSocket.on("startType", function(clientNickname){
    console.log("User " + clientNickname + " is writing a message...");
    typingUsers[clientNickname] = 1;
    io.emit("userTypingUpdate", typingUsers);
  });


  clientSocket.on("stopType", function(clientNickname){
    console.log("User " + clientNickname + " has stopped writing a message...");
    delete typingUsers[clientNickname];
    io.emit("userTypingUpdate", typingUsers);
  });

});
var Gpio = require('onoff').Gpio;
var buttonOne = new Gpio(17, 'in', 'both');
var buttonTwo = new Gpio(23, 'in', 'both');
const LCD = require('raspberrypi-liquid-crystal');
const lcd = new LCD(1, 0x27, 16, 2);
const { exec } = require("child_process");
const realtimeStdout = require('realtime-stdout')
const readLastLines = require('read-last-lines');

menuOp1 = "Manjaro 21.02"
menuOp2 = "Pop OS! 21.10"
menuOp3 = "Windows 10 21H2"

menuNumber = 0
menuText = menuOp1
watchForone = 1

lcd.beginSync();
lcd.clearSync();
lcd.printLineSync(0, menuText);

buttonOne.watch(function (err, value) {
  if (err) {
    console.error('error', err);
  return;
  }
  if (watchForone == 1) {
  if (value == 1) {
     lcd.clearSync()
     if (menuNumber == 0 || menuNumber == 1) {
        menuNumber = menuNumber + 1
     } else if (menuNumber == 2) {
        menuNumber = 0
     } else {
        menuNumber = 0
     }
     if (menuNumber == 0) {
        menuText = menuOp1
     } else if (menuNumber == 1) {
        menuText = menuOp2
     } else if (menuNumber == 2) {
        menuText = menuOp3
     } else {
        menuText = "none"
     }
     lcd.printLineSync(0, menuText);
  }
 }
});

buttonTwo.watch(function (err, value) {
  if (err) {
    console.error('error', err);
  return;
  }
  if (value == 1) {
     watchForone = 0
     lcd.printLineSync(1, "Working...");
stdout = ''

const cp = realtimeStdout('./creation.sh', [`${menuNumber}`], {}, data => (stdout = data))

cp.on('spawn', () => {
var readThestat = setInterval(() => {
      lcd.clearSync()
      lcd.printLineSync(0, `${menuText}`)
      lcd.printLineSync(1, `${stdout.trim()}`);
}, 1000)
cp.on('close', () => {
  if (`${stdout.trim()}` == "completed") {
       lcd.clearSync();
       lcd.printLineSync(0, `${menuText}`)
       lcd.printLineSync(1, "completed");
  } else if (`${stdout.trim()}` == "no usb") {
       lcd.clearSync();
       lcd.printLineSync(0, `${menuText}`)
       lcd.printLineSync(1, "no usb found");
  } else {
       lcd.clearSync();
       lcd.printLineSync(0, `${menuText}`)
       lcd.printLineSync(1, "failed!");
  }
  watchForone = 1
  clearInterval(readThestat);
});
});
 }
});

function unexportOnClose() {
  buttonOne.unexport();
  buttonTwo.unexport();
};

process.on('SIGINT', unexportOnClose);

var fs = require('fs');
//var https = require('https');
//var args = process.argv.slice(2);

const currentDirectory = process.cwd();

var googleAPIKey = "";//SET WHEN GOING TO USE!!!
var cwdSplit = currentDirectory.split("\\");
console.log("currentDirectory = " + currentDirectory);
var lastDirSplit = cwdSplit.slice(0, -1);
var lastDir = lastDirSplit.join("\\");
console.log("lastDir = " + lastDir);
fs.readFile(lastDirSplit.join("/") + "/google_api_key.txt", function (err, apiKey) {
    if (err) {
        console.log("ERROR GETTING GOOGLE API KEY: " + JSON.stringify(err));
    } else {
        googleAPIKey = apiKey;
        var lgPath = currentDirectory + "/android/fastlane/metadata/android";
        fs.readdir(lgPath, (err, transFiles) => {
            transFiles = transFiles.filter(function (file) {
                return fs.statSync(lgPath + '/' + file.split("/")[0]).isDirectory();
            });
            console.log("transFiles = " + transFiles);
            console.log("NUMBER FILES = " + transFiles.length);
            var full_description;
            for (var i = 0; i < transFiles.length; i++) {
                try {
                    full_description = fs.readFileSync(currentDirectory + "/android/fastlane/metadata/android/" + transFiles[i] + "/full_description.txt");
                } catch (e) {
                    console.log("\n" + transFiles[i] + ", full_description: NULL!");
                }
            }
        });
    }
});
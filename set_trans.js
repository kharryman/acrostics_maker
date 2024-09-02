var fs = require('fs');
//var https = require('https');
var request = require('request');
var args = process.argv.slice(2);
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
        fs.readdir(currentDirectory + "/assets/i18n", (err, files) => {

            var transFile = "af", transFiles = [], fileSplit = [];
            var transKey = args[0];
            var transString = args[1];

            var numTrans = 0;
            files.forEach(file => {
                fileSplit = file.split(".");
                if (fileSplit.slice(-1)[0] === "json") {
                    numTrans++;
                    //console.log("FILE:" + file);
                    fileSplit.pop();
                    transFile = fileSplit.join(".");
                    console.log("transFile = " + transFile);
                    transFiles.push(transFile);
                }
            });
            console.log("NUMBER FILES = " + numTrans);

            var createJsonFile = function (fileIndex, transKey, transString, transFiles) {
                if (fileIndex < transFiles.length) {
                    var targetLanguage = transFiles[fileIndex];
                    fs.readFile(currentDirectory + "/assets/i18n/" + targetLanguage + ".json", function (err, jsonStr) {
                        if (err) {
                            console.log("READ FILE ERROR: " + JSON.stringify(err));
                        }
                        console.log("READ FILE: " + targetLanguage + ".json!");
                        var transObj = JSON.parse(jsonStr);
                        //console.log("TRANS FILE JSON # KEYS BEFORE = " + Object.keys(transObj).length);

                        //if (transObj[transKey]) {
                        //    //ALREADY EXISTS, DO NEXT(CONTINUE)!
                        //    console.log("ALREADY EXISTS, CONTINUE!");
                        //    fileIndex++;
                        //    createJsonFile(fileIndex, transKey, transString, transFiles);
                        //}else
                        if (targetLanguage.includes("en")) {
                            transObj[transKey] = transString;
                            var transObjOrdered = Object.keys(transObj).sort().reduce(
                                (obj, key) => {
                                    obj[key] = transObj[key];
                                    return obj;
                                },
                                {}
                            );
                            fs.writeFile(currentDirectory + "/assets/i18n/" + targetLanguage + ".json", JSON.stringify(transObjOrdered, null, 4), 'utf8', function () {
                                console.log("WROTE FILE: " + targetLanguage + ".json");
                                fileIndex++;
                                setTimeout(function () {
                                    createJsonFile(fileIndex, transKey, transString, transFiles);
                                }, 100);
                            });
                        } else {
                            var url = 'https://translation.googleapis.com/language/translate/v2?key=' + googleAPIKey;
                            url += '&q=' + encodeURI(transString);
                            url += `&source=en`;
                            url += `&target=` + targetLanguage;
                            url += `&format=text`;
                            request(url, function (error, response, body) {
                                if (!error && response.statusCode == 200) {
                                    var parsedBody = JSON.parse(body);
                                    //console.log("SET transKey body = " + JSON.stringify(parsedBody, null, 4));
                                    //console.log("SET transKey body.data = " + JSON.stringify(parsedBody.data, null, 4));
                                    //console.log("parsedBody.data.translations = " + JSON.stringify(parsedBody.data.translations));
                                    var translatedText = parsedBody.data.translations[0].translatedText;
                                    //console.log("translatedText = " + translatedText);
                                    transObj[transKey] = translatedText;
                                    console.log("transKey = " + transKey + ", transObj[transKey] = " + transObj[transKey]);
                                    var transObjOrdered = Object.keys(transObj).sort().reduce(
                                        (obj, key) => {
                                            obj[key] = transObj[key];
                                            return obj;
                                        },
                                        {}
                                    );
                                    //console.log("TRANS FILE JSON # KEYS AFTER = " + Object.keys(transObjOrdered).length);
                                    //console.log("NEW  transObjOrdered = " + JSON.stringify(transObjOrdered));

                                    fs.writeFile(currentDirectory + "/assets/i18n/" + targetLanguage + ".json", JSON.stringify(transObjOrdered, null, 4), 'utf8', function () {
                                        console.log("WROTE FILE: " + targetLanguage + ".json");
                                        fileIndex++;
                                        setTimeout(function () {
                                            createJsonFile(fileIndex, transKey, transString, transFiles);
                                        }, 100);
                                    });
                                } else {
                                    console.log("google cloud translate ERROR: " + JSON.stringify(error) + ", RESPONSE = " + JSON.stringify(response) + ", BODY = " + JSON.stringify(body));
                                }
                            });
                        }
                    });
                } else {
                    console.log("ALL DONE TRANSLATING SAVE NEW JSON FILES!");
                }
            }
            createJsonFile(0, transKey, transString, transFiles);
        });
    }
});
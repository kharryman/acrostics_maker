var fs = require('fs');
const currentDirectory = process.cwd();
const srcDir = "../mnemonics_maker";
var cwdSplit = currentDirectory.split("\\");

const transKeys = ["POPUP_NO_ADS_MESSAGE2", "POPUP_NO_ADS_TITLE", "PROMPT_ADS_FREE", "PROMPT_AND_OFFLINE", "PROMPT_GET_APP_NO_ADS", "PROMPT_LETS_GO", "PROMPT_NO_REMOVE_AD_PRODUCT", "PROMPT_NO_THANK_YOU", "PROMPT_ONLY", "PROMPT_PURCHASE_ERROR", "PROMPT_RESTORE_PURCHASES", "PROMPT_RESTORING", "PROMPT_SUCCESS", "PROMPT_SUPPORT_US", "PROMPT_YES_NOW", "THANK_YOU_NO_ADS"];

fs.readdir(currentDirectory + "/assets/i18n", (err, files) => {

    var transFile = "af", transFiles = [], fileSplit = [];

    var numTrans = 0;
    files.forEach(file => {
        fileSplit = file.split(".");
        if (fileSplit.slice(-1)[0] === "json") {
            numTrans++;
            //console.log("FILE:" + file);
            fileSplit.pop();
            transFile = fileSplit.join(".");
            //console.log("transFile = " + transFile);
            transFiles.push(transFile);
        }
    });
    console.log("NUMBER FILES = " + numTrans);

    var createJsonFile = function (fileIndex, transFiles) {
        if (fileIndex < transFiles.length) {
            var targetLanguage = transFiles[fileIndex];

            //GET SRC
            const srcFile = srcDir + "/assets/i18n/" + targetLanguage + ".json";
            fs.readFile(srcFile, (err, jsonStr) => {
                var srcTransObj = {};
                if (err) {
                    console.log("READ SRC FILE ERROR: " + JSON.stringify(err));
                }else{
                    srcTransObj = JSON.parse(jsonStr);
                   console.log("READ SRC FILE: " + srcFile);
                }
                var filteredTransObj = {};
                for (var i = 0; i < transKeys.length; i++) {
                    if (srcTransObj[transKeys[i]]) {
                        filteredTransObj[transKeys[i]] = srcTransObj[transKeys[i]];
                    }
                }
                //console.log("GOT SRC filteredTransObj: " + JSON.stringify(filteredTransObj));

                //GET DEST:
                fs.readFile(currentDirectory + "/assets/i18n/" + targetLanguage + ".json", function (err, jsonStr) {
                    if (err) {
                        console.log("READ DEST FILE ERROR: " + JSON.stringify(err));
                    }
                    console.log("READ DEST FILE: " + targetLanguage + ".json!");
                    var destTransObj = JSON.parse(jsonStr);

                    for (var prop in filteredTransObj) {
                        destTransObj[prop] = filteredTransObj[prop];
                    }
                    //console.log("GOT TRANSFILE, " + transFiles[fileIndex] + ", = " + JSON.stringify(destTransObj));
                    var transObjOrdered = Object.keys(destTransObj).sort().reduce(
                        (obj, key) => {
                            obj[key] = destTransObj[key];
                            return obj;
                        },
                        {}
                    );

                    console.log("transFile: " + transFiles[fileIndex] + ": " + JSON.stringify(transObjOrdered, null, 2));

                    fs.writeFile(currentDirectory + "/assets/i18n/" + targetLanguage + ".json", JSON.stringify(transObjOrdered, null, 4), 'utf8', function () {
                        console.log("WROTE FILE: " + targetLanguage + ".json");
                        fileIndex++;
                        createJsonFile(fileIndex, transFiles);
                    });
                });
            });
        } else {
            console.log("ALL DONE TRANSLATING SAVE NEW JSON FILES!");
        }
    };

    createJsonFile(0, transFiles);
});
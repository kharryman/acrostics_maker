var XLSX = require('xlsx');
var fs = require('fs');
//var filePath = "";
var transFile = "af", transFiles = [], fileSplit = [];
const currentDirectory = process.cwd();

fs.readdir(currentDirectory + "/android/fastlane/metadata/trans", (err, files) => {
    var numTrans = 0;
    files.forEach(file => {
        fileSplit = file.split(".");
        if (fileSplit.slice(-1)[0] === "xlsx" && file !== "trans.xlsx") {
            numTrans++;
            //console.log("FILE:" + file);
            fileSplit.pop();
            transFile = fileSplit.join(".");
            console.log("transFile = " + transFile);
            transFiles.push(transFile);
        }
    });
    //transFiles = ["af"];
    console.log("NUMBER FILES = " + numTrans);

    var createJsonFile = function (fileIndex, transFiles) {
        var transFile = transFiles[fileIndex];
        if (fileIndex < transFiles.length) {
            var workbook = XLSX.readFile(currentDirectory + "/android/fastlane/metadata/trans/" + transFile + ".xlsx");
            var sheet_name_list = workbook.SheetNames;
            //console.log(JSON.stringify(XLSX.utils.sheet_to_json(workbook.Sheets[sheet_name_list[0]])))

            sheet_name_list.forEach(async function (y) {//SHOULD ONLY HAVE 1 SHEET=>
                var worksheet = workbook.Sheets[y];
                var arr = [];
                for (z in worksheet) {
                    if (z[0] === '!') continue;
                    //parse out the column, row, and value
                    //var col = z.substring(0,1);
                    //var row = parseInt(z.substring(1));
                    var value = worksheet[z].v.trimLeft();
                    arr.push(value);
                }
                if (arr.length > 0) {
                    var fullDesc = arr[0];
                    //console.log(JSON.stringify(transJSON));
                    fs.writeFile(currentDirectory + "/android/fastlane/metadata/android/" + transFile + "/full_description.txt", fullDesc, 'utf8', function () {
                        console.log("WROTE FILE: full_description.txt FOR " + transFile + ".");
                        fileIndex++;
                        createJsonFile(fileIndex, transFiles);
                    });
                }
            });
        } else {
            console.log("ALL DONE!");
        }
    }
    createJsonFile(0, transFiles);

});
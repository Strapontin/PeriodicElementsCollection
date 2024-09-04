const fs = require("fs-extra");
const path = require("path");

const outputDir = "../metadata"
if (!fs.existsSync(outputDir)){
    fs.mkdirSync(outputDir);
}

// Path to the input JSON file
const inputFile = path.join(__dirname, "../elements.json");

// Path to the output JSON file
const outputFile = path.join(__dirname, "../NFTElements.json");

// Function to read the input JSON file
function readInputFile() {
  return fs
    .readJson(inputFile)
    .then((data) => {
      // console.log('Input file contents:', data);
      return data;
    })
    .catch((err) => {
      console.error("Error reading input file:", err);
      return null;
    });
}

// Function to create the output JSON file
function createOutputFile(dataArray) {
  if (!dataArray || dataArray.length === 0) {
    console.error("No data to write to output file.");
    return;
  }
  console.log(typeof dataArray);

  // Process each item in the input array
  const processedItems = dataArray.map(async (element) => {
    // Select specific data to write to the output file
    const selectedData = {
      name: element.name,
      description: element.summary,
      image:
        "https://gray-acute-wildfowl-4.mypinata.cloud/ipfs/QmXBS6G6ZytV5mMxfpXGdr2CKfGzG38t1JZcypBkAfFpAs/test_" +
        element.number +
        ".png",
      external_url: "todo",
      attributes: [
        {
          trait_type: "RAM",
          value: element.atomic_mass * 1e18,
        },
        {
          trait_type: "Level",
          value: element.period,
        },
      ],
    };

    const outputFile = path.join(__dirname, `${outputDir}/${element.number}.json`);

    try {
      await fs.writeJson(outputFile, selectedData);
      console.log(
        `Created ${selectedData.name}'s entry in output file ${outputFile}`
      );
    } catch (err) {
      console.error(`Error creating output file for ${item.name}:`, err);
    }

    // Add any custom processing here if needed
    return selectedData;
  });

  //   // Write the processed data to the output file
  //   return fs
  //     .writeJson(outputFile, processedItems)
  //     .then(() => {
  //       console.log(`Created ${processedItems.length} entry(s) in output file.`);
  //     })
  //     .catch((err) => {
  //       console.error("Error creating output file:", err);
  //     });
}

// Main execution flow
async function main() {
  try {
    const inputContent = await readInputFile();
    await createOutputFile(inputContent.elements);
  } catch (err) {
    console.error("An error occurred during execution:", err);
  }
}

main();

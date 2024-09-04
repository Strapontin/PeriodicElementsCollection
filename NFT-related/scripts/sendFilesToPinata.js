const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const JWT = process.env.PINATA_API_KEY; // Fetch the JWT from the .env file

const pinFileToIPFS = async (filePath) => {
    const formData = new FormData();
    const file = fs.createReadStream(filePath);
    formData.append('file', file);

    const pinataMetadata = JSON.stringify({
        name: path.basename(filePath), // Use the file name as the metadata name
    });
    formData.append('pinataMetadata', pinataMetadata);

    const pinataOptions = JSON.stringify({
        cidVersion: 0,
    });
    formData.append('pinataOptions', pinataOptions);

    try {
        const res = await axios.post("https://api.pinata.cloud/pinning/pinFileToIPFS", formData, {
            maxBodyLength: "Infinity",
            headers: {
                'Content-Type': `multipart/form-data; boundary=${formData._boundary}`,
                'Authorization': `Bearer ${JWT}`
            }
        });
        console.log(`Successfully pinned ${filePath}:`, res.data);
    } catch (error) {
        console.error(`Failed to pin ${filePath}:`, error.response?.data || error.message);
    }
};

const pinAllPngFiles = async (folderPath) => {
    fs.readdir(folderPath, async (err, files) => {
        if (err) {
            return console.error('Unable to scan directory:', err);
        }

        for (const file of files) {
            const filePath = path.join(folderPath, file);
            if (path.extname(file).toLowerCase() === '.png') {
                await pinFileToIPFS(filePath);
            }
        }
    });
};

// Replace 'path/to/your/folder' with the path to the folder containing .png files
pinAllPngFiles('./images');

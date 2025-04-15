const express = require('express');
const bodyParser = require('body-parser');
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const app = express();
const port = process.env.PORT || 9000;
const webhookSecret = process.env.WEBHOOK_SECRET || 'changeme';

// Parse JSON requests
app.use(bodyParser.json());

// Simple logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  next();
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).send('Webhook receiver is healthy');
});

// Webhook endpoint for Ghost
app.post('/webhook/:siteName', (req, res) => {
  const { siteName } = req.params;
  const signature = req.headers['x-ghost-signature'];
  
  // Verify the signature if provided
  if (signature) {
    const payload = JSON.stringify(req.body);
    const hmac = crypto.createHmac('sha256', webhookSecret)
      .update(payload)
      .digest('hex');
    
    if (hmac !== signature) {
      console.log(`Invalid signature for site ${siteName}`);
      return res.status(401).send('Invalid signature');
    }
  }
  
  console.log(`Received webhook for site: ${siteName}`);
  
  // Check if site exists
  const sitesDir = '/app/sites';
  try {
    fs.accessSync(`/sites/${siteName}`, fs.constants.F_OK);
  } catch (err) {
    console.error(`Site ${siteName} not found`);
    return res.status(404).send(`Site ${siteName} not found`);
  }
  
  // Find the domain from site.env file
  let siteDomain = '';
  try {
    // Attempt to find the site directory by searching for site.env files
    const allSites = fs.readdirSync('/sites');
    for (const site of allSites) {
      try {
        const envPath = `/sites/${site}/site.env`;
        if (fs.existsSync(envPath)) {
          const envContent = fs.readFileSync(envPath, 'utf8');
          const siteNameMatch = envContent.match(/SITE_NAME=(.+)/);
          if (siteNameMatch && siteNameMatch[1] === siteName) {
            const domainMatch = envContent.match(/SITE_DOMAIN=(.+)/);
            if (domainMatch) {
              siteDomain = domainMatch[1];
              break;
            }
          }
        }
      } catch (e) {
        console.error(`Error reading site directory ${site}:`, e);
      }
    }
  } catch (err) {
    console.error('Error finding site domain:', err);
    return res.status(500).send('Error finding site domain');
  }
  
  if (!siteDomain) {
    console.error(`Domain for site ${siteName} not found`);
    return res.status(404).send(`Domain for site ${siteName} not found`);
  }
  
  // Execute the static site generation command
  const outputDir = `/output/${siteDomain}`;
  
  // Create output directory if it doesn't exist
  if (!fs.existsSync(outputDir)) {
    try {
      fs.mkdirSync(outputDir, { recursive: true });
    } catch (err) {
      console.error(`Error creating directory ${outputDir}:`, err);
      return res.status(500).send('Error creating output directory');
    }
  }
  
  const command = `docker exec static-generator gssg --url http://ghost_${siteName}:2368 --dest ${outputDir}`;
  
  console.log(`Executing command: ${command}`);
  
  exec(command, (error, stdout, stderr) => {
    if (error) {
      console.error(`Error generating static site for ${siteName}:`, error);
      console.error(stderr);
      return res.status(500).send(`Error generating static site: ${error.message}`);
    }
    
    console.log(`Static site for ${siteName} generated successfully`);
    console.log(stdout);
    
    res.status(200).send('Static site generation triggered');
  });
});

// Start the server
app.listen(port, () => {
  console.log(`Webhook receiver listening on port ${port}`);
});

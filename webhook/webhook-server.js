const express = require('express');
const bodyParser = require('body-parser');
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const app = express();
const port = process.env.PORT || 9000;
const webhookSecret = process.env.WEBHOOK_SECRET || 'changeme';

// Track running static site generations
const runningGenerations = new Map();
// Track pending generation requests (to avoid duplicate runs)
const pendingGenerations = new Set();

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

// Function to generate static site
function generateStaticSite(siteName, siteDomain) {
  return new Promise((resolve, reject) => {
    if (runningGenerations.has(siteName)) {
      console.log(`Static site generation already running for ${siteName}, will skip this request`);
      return resolve(false);
    }
    
    // Mark this site as being generated
    runningGenerations.set(siteName, Date.now());
    // Remove from pending
    pendingGenerations.delete(siteName);
    
    const outputDir = `/output/${siteDomain}`;
    
    // Create output directory if it doesn't exist
    if (!fs.existsSync(outputDir)) {
      try {
        fs.mkdirSync(outputDir, { recursive: true });
      } catch (err) {
        console.error(`Error creating directory ${outputDir}:`, err);
        runningGenerations.delete(siteName);
        return reject(new Error(`Error creating output directory: ${err.message}`));
      }
    }
    
    const command = `docker exec static-generator gssg --url http://ghost_${siteName}:2368 --dest ${outputDir}`;
    
    console.log(`Executing command: ${command}`);
    
    exec(command, (error, stdout, stderr) => {
      if (error) {
        console.error(`Error generating static site for ${siteName}:`, error);
        console.error(stderr);
        runningGenerations.delete(siteName);
        return reject(new Error(`Error generating static site: ${error.message}`));
      }
      
      console.log(`Static site for ${siteName} generated successfully`);
      console.log(stdout);
      
      // Update git repository
      const gitCommand = `cd /scripts && ./update-git-repository.sh ${siteDomain}`;
      console.log(`Executing git update command: ${gitCommand}`);
      
      exec(gitCommand, (gitError, gitStdout, gitStderr) => {
        if (gitError) {
          console.error(`Error updating git repository for ${siteName}:`, gitError);
          console.error(gitStderr);
          // We don't reject here because the site was generated successfully
        } else {
          console.log(`Git repository for ${siteName} updated successfully`);
          console.log(gitStdout);
        }
        
        // Remove from running
        runningGenerations.delete(siteName);
        
        // Check if there's a pending request for this site
        if (pendingGenerations.has(siteName)) {
          console.log(`Found pending generation request for ${siteName}, triggering now`);
          pendingGenerations.delete(siteName);
          // Start a new generation
          generateStaticSite(siteName, siteDomain).catch(err => {
            console.error(`Error in follow-up generation for ${siteName}:`, err);
          });
        }
        
        resolve(true);
      });
    });
  });
}

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
  
  // Check if generation is already running for this site
  if (runningGenerations.has(siteName)) {
    console.log(`Static site generation already running for ${siteName}, marking as pending`);
    pendingGenerations.add(siteName);
    return res.status(202).send('Static site generation already in progress, request queued');
  }
  
  // Check if we have a pending generation for this site
  if (pendingGenerations.has(siteName)) {
    console.log(`Static site generation already pending for ${siteName}, no action needed`);
    return res.status(202).send('Static site generation already queued');
  }
  
  // Start generating the static site
  generateStaticSite(siteName, siteDomain)
    .then(() => {
      console.log(`Completed static site generation process for ${siteName}`);
    })
    .catch(err => {
      console.error(`Error during static site generation for ${siteName}:`, err);
    });
  
  // Immediately respond to the webhook
  res.status(202).send('Static site generation triggered');
});

// Start the server
app.listen(port, () => {
  console.log(`Webhook receiver listening on port ${port}`);
});


// Start the server
app.listen(port, () => {
  console.log(`Webhook receiver listening on port ${port}`);
});

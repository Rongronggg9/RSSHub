let puppeteer;
const wait = require('../../lib/utils/wait');
const cheerio = require('cheerio');

let browser_slot = null;

afterEach(() => {
    if (browser_slot) {
        browser_slot.close(); // double insurance if test fails
        browser_slot = null;
    }
    jest.resetModules();
});

afterAll(() => {
    // https://stackoverflow.com/questions/50793885/referenceerror-you-are-trying-to-import-a-file-after-the-jest-environment-has
    jest.useFakeTimers();
});

describe('puppeteer', () => {
    it('puppeteer run', async () => {
        puppeteer = require('../../lib/utils/puppeteer');
        const browser = await puppeteer();
        browser_slot = browser;
        const startTime = Date.now();
        const page = await browser.newPage();
        await page.goto('https://www.cloudflare.com/', {
            waitUntil: 'domcontentloaded',
        });

        // eslint-disable-next-line no-undef
        const html = await page.evaluate(() => document.body.innerHTML);
        expect(html.length).toBeGreaterThan(0);

        expect((await browser.process()).signalCode).toBe(null);
        const sleepTime = 31 * 1000 - (Date.now() - startTime);
        if (sleepTime > 0) {
            await wait(sleepTime);
        }
        expect((await browser.process()).signalCode).toBe('SIGKILL');
    }, 40000);
    it('puppeteer without stealth', async () => {
        puppeteer = require('../../lib/utils/puppeteer');
        const browser = await puppeteer({ stealth: false });
        browser_slot = browser;
        const page = await browser.newPage();
        await page.goto('https://bot.sannysoft.com', {
            waitUntil: 'networkidle0',
        });

        const html = await page.evaluate(() => document.body.innerHTML);
        const $ = cheerio.load(html);
        browser.close();

        const webDriverTest = $('tbody tr').eq(2).find('td').eq(1).text().trim();
        const chromeTest = $('tbody tr').eq(4).find('td').eq(1).text().trim();
        expect(webDriverTest).toBe('present (failed)');
        expect(chromeTest).toBe('missing (failed)');
    }, 10000);
    it('puppeteer with stealth', async () => {
        puppeteer = require('../../lib/utils/puppeteer');
        const browser = await puppeteer({ stealth: true });
        browser_slot = browser;
        const page = await browser.newPage();
        await page.goto('https://bot.sannysoft.com', {
            waitUntil: 'networkidle0',
        });

        const html = await page.evaluate(() => document.body.innerHTML);
        const $ = cheerio.load(html);
        browser.close();
        const webDriverTest = $('tbody tr').eq(2).find('td').eq(1).text().trim();
        const chromeTest = $('tbody tr').eq(4).find('td').eq(1).text().trim();
        expect(webDriverTest).toBe('missing (passed)');
        expect(chromeTest).toBe('present (passed)');
    }, 10000);
});

const logger = require('./logger');
const config = require('@/config').value;
const got = require('got');

const custom = got.extend({
    retry: config.requestRetry,
    hooks: {
        beforeRetry: [
            (options, err, count) => {
                logger.error(`Request ${options.url} fail, retry attempt #${count}: ${err}`);
                if (err.response.statusCode === 429) {
                    let sleepTime = +(err.response.headers['retry-after'] ?? err.response.headers['x-rate-limit-remaining'] ?? 10);
                    sleepTime = !isNaN(sleepTime) ? sleepTime : 10;
                    if (sleepTime > 15) {
                        err.message = `Rate limit exceeded, the request has been aborted, please try again after ${sleepTime}s`;
                        throw err;
                    }
                    logger.error(`Rate limit exceeded, retrying in ${sleepTime}s...`);
                    return new Promise((resolve) => setTimeout(resolve, sleepTime * 1000));
                }
            },
        ],
        afterResponse: [
            (response) => {
                try {
                    response.data = JSON.parse(response.body);
                } catch (e) {
                    response.data = response.body;
                }
                response.status = response.statusCode;
                return response;
            },
        ],
        init: [
            (options) => {
                // compatible with axios api
                if (options && options.data) {
                    options.body = options.body || options.data;
                }
            },
        ],
    },
    headers: {
        'user-agent': config.ua,
    },
    timeout: config.requestTimeout,
});
custom.all = (list) => Promise.all(list);

module.exports = custom;

const test = require("node:test");
const assert = require("node:assert");

test("basic application test", () => {
    const result = 1 + 1;

    assert.strictEqual(result, 2);
});
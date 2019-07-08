"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
var _exportNames = {
  make: true
};
exports.make = void 0;

var _channel = require("./channel.bs");

Object.keys(_channel).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  if (Object.prototype.hasOwnProperty.call(_exportNames, key)) return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function () {
      return _channel[key];
    }
  });
});

// Receiving from a channel until it's closed is normally done using for range
// make it async iterator here
const make = (...args) => {
  const chan = (0, _channel.make)(...args);

  chan[Symbol.asyncIterator] = () => ({
    next: () => {
      if (!(0, _channel.is_completed)(chan)) {
        return (0, _channel.take)(chan).then(value => ({
          value,
          done: false
        }));
      }

      return Promise.resolve({
        done: true
      });
    }
  });

  return chan;
};

exports.make = make;
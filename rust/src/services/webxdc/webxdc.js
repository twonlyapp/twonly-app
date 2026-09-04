// The webxdc API, served at /webxdc.js for every app and overriding whatever
// the bundle ships under that name.
//
// Nothing here is a security boundary: the page can rewrite `window.webxdc`
// the moment this script finishes. Every limit expressed below is a courtesy
// to honest apps and is enforced again on the Rust side, which is where the
// real checks live.
'use strict';

(function () {
  // Substituted by the host when this file is served. The values never travel
  // through the page, so app code cannot influence what they say.
  const init = __TWONLY_WEBXDC_INIT__;

  // The transport the platform installed before any page script ran. Captured
  // now so a later overwrite by app code cannot redirect our own calls.
  //
  // Android answers synchronously and returns the reply; iOS posts and the
  // reply arrives through `__twonlyWebxdcDeliver`. Both are handled below.
  const androidBridge = window.__twonlyWebxdcBridge;
  const iosBridge =
    window.webkit &&
    window.webkit.messageHandlers &&
    window.webkit.messageHandlers.twonlyWebxdc;

  function transport(json) {
    if (androidBridge && androidBridge.call) {
      return androidBridge.call(json);
    }
    if (iosBridge) {
      iosBridge.postMessage(json);
      return null;
    }
    throw new Error('the webxdc bridge is unavailable');
  }

  let nextCallId = 1;
  const pending = new Map();

  function call(method, params) {
    return new Promise(function (resolve, reject) {
      const id = nextCallId++;
      pending.set(id, { resolve: resolve, reject: reject });
      try {
        const reply = transport(
          JSON.stringify({ id: id, method: method, params: params || {} })
        );
        if (typeof reply === 'string' && reply.length > 0) {
          window.__twonlyWebxdcDeliver(JSON.parse(reply));
        }
      } catch (error) {
        pending.delete(id);
        reject(error);
      }
    });
  }

  function decodeBase64(value) {
    const binary = atob(value || '');
    const bytes = new Uint8Array(binary.length);
    for (let index = 0; index < binary.length; index++) {
      bytes[index] = binary.charCodeAt(index);
    }
    return bytes;
  }

  let listener = null;
  let lastSerial = 0;

  // The host calls this; apps have no reason to.
  window.__twonlyWebxdcDeliver = function (message) {
    if (message.id && pending.has(message.id)) {
      const entry = pending.get(message.id);
      pending.delete(message.id);
      if (message.error) entry.reject(new Error(message.error));
      else entry.resolve(message.result);
      return;
    }
    if (message.method === 'update' && listener) {
      for (const update of message.params.updates) {
        lastSerial = update.serial;
        try {
          listener(update);
        } catch (error) {
          console.error('webxdc update listener threw', error);
        }
      }
    }
  };

  const webxdc = {
    selfAddr: init.selfAddr,
    selfName: init.selfName,

    // Advertised so apps can pace themselves. The host applies both limits
    // independently and rejects what exceeds them.
    sendUpdateInterval: init.sendUpdateInterval,
    sendUpdateMaxSize: init.sendUpdateMaxSize,

    sendUpdate: function (update, descr) {
      return call('sendUpdate', {
        payload: update.payload === undefined ? null : update.payload,
        info: update.info,
        href: update.href,
        summary: update.summary,
        document: update.document,
        notify: update.notify,
        descr: descr,
      });
    },

    setUpdateListener: function (callback, serial) {
      listener = callback;
      lastSerial = serial || 0;
      return call('catchUp', { serial: lastSerial });
    },

    sendToChat: function (message) {
      // Always routed through a picker on the host side: an app never chooses
      // who receives something on the user's behalf, and the user may abandon
      // it entirely.
      //
      // Only the text is carried. twonly has no message type for an arbitrary
      // file, so a call with one is refused rather than half honoured -- and
      // the file is not read here, since reading it could only be wasted work.
      var file = message && message.file;
      return call('sendToChat', {
        text: message && message.text,
        file: file ? { name: file.name } : undefined,
      });
    },

    importFiles: function (filters) {
      return call('importFiles', filters || {}).then(function (files) {
        // The host hands back bytes; the File objects the app expects can only
        // be built in here.
        return (files || []).map(function (file) {
          return new File([decodeBase64(file.base64)], file.name, {
            type: file.type || '',
          });
        });
      });
    },

    joinRealtimeChannel: function () {
      // Not implemented on purpose. A peer-to-peer channel would give the app
      // the network access the rest of this design spends its effort denying,
      // and would expose both peers' addresses to each other.
      console.warn('webxdc: realtime channels are not available in twonly');
      return Object.freeze({
        setListener: function () {},
        send: function () {},
        leave: function () {},
      });
    },
  };

  // Left writable on purpose. The API hands out a single update listener, so an
  // app that needs two consumers -- a game and its scoreboard, say -- has
  // nowhere to multiplex them but here, and wrapping `setUpdateListener` is how
  // apps in the wild do it. A frozen object broke those apps silently: outside
  // strict mode the assignment is discarded without an error, and the app then
  // registers listeners that never fire.
  //
  // Nothing is given up by allowing it. The transport is closed over rather than
  // reachable through this object, and every limit is applied again in Rust, so
  // what the page does to `window.webxdc` only ever affects the page itself.
  window.webxdc = webxdc;
})();

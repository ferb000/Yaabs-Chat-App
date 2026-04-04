importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyDTUIYTZUNMjLCBYby2aFfxBPrWKrjrGQE",
  authDomain: "glady-ce3fe.firebaseapp.com",
  projectId: "glady-ce3fe",
  storageBucket: "glady-ce3fe.firebasestorage.app",
  messagingSenderId: "1081636730361",
  appId: "1:1081636730361:web:b2f895f04828b1d0cdf928",
});

const messaging = firebase.messaging();

// Optional: log background messages
messaging.onBackgroundMessage((message) => {
  console.log("onBackgroundMessage", message);
});
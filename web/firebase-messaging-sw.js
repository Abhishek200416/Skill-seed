// web/firebase-messaging-sw.js
/* eslint-disable no-undef */
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

// Paste your Firebase config here (same values as in firebase_options.dart)
firebase.initializeApp({
  apiKey: "YOUR_KEY",
  authDomain: "YOUR_APP.firebaseapp.com",
  projectId: "YOUR_PROJECT_ID",
  storageBucket: "YOUR_APP.appspot.com",
  messagingSenderId: "YOUR_SENDER_ID",
  appId: "YOUR_APP_ID"
});

// Optional: background handler (keeps SW alive)
const messaging = firebase.messaging();
messaging.onBackgroundMessage((payload) => {
  // Customize notification if you want
  self.registration.showNotification(
    payload.notification?.title || 'New message',
    {
      body: payload.notification?.body || '',
      icon: '/icons/Icon-192.png'
    }
  );
});

import { initializeApp } from 'firebase/app';
import { getAuth, GoogleAuthProvider } from 'firebase/auth';

const firebaseConfig = {
  apiKey: 'AIzaSyAs8SThYkByqnEnNhPzWv9rpDbRK6CKkTo',
  authDomain: 'vocabofinalapp.firebaseapp.com',
  projectId: 'vocabofinalapp',
  storageBucket: 'vocabofinalapp.firebasestorage.app',
  messagingSenderId: '1060637668034',
  appId: '1:1060637668034:web:e02e11427a579b9ede015b',
  measurementId: 'G-12XE10LPLT',
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const googleProvider = new GoogleAuthProvider();

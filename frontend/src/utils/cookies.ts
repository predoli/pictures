import Cookies from 'js-cookie';

const LAST_IMAGE_COOKIE = 'photo-frame-last-image';
const COOKIE_EXPIRES = 365; // days

export const cookieUtils = {
  saveLastImage(filename: string): void {
    Cookies.set(LAST_IMAGE_COOKIE, filename, { expires: COOKIE_EXPIRES });
  },

  getLastImage(): string | undefined {
    return Cookies.get(LAST_IMAGE_COOKIE);
  },

  clearLastImage(): void {
    Cookies.remove(LAST_IMAGE_COOKIE);
  }
};
import { ref, onMounted, onUnmounted, watch } from 'vue';
import { convertFileSrc } from '@tauri-apps/api/core';
import type { Image, ImagesResponse, OrderingMode } from '../types';
import { cookieUtils } from '../utils/cookies';

const API_BASE = 'http://localhost:8080';
const SLIDE_INTERVAL = 15000; // 15 seconds
const IMAGES_PER_BATCH = 10;
const PRELOAD_AHEAD_COUNT = 5; // Number of images to preload ahead

export function usePhotoFrame(preloadAheadCount: number = PRELOAD_AHEAD_COUNT) {
  const images = ref<Image[]>([]);
  const currentIndex = ref(0);
  const isPaused = ref(false);
  const currentOrdering = ref<OrderingMode>('date_asc');
  const totalCount = ref(0);
  const isLoading = ref(false);
  const error = ref<string | null>(null);
  const preloadedImages = ref<Set<number>>(new Set()); // Track which images are preloaded

  let slideInterval: number | null = null;

  const preloadImage = (imageIndex: number): void => {
    if (preloadedImages.value.has(imageIndex) || !images.value[imageIndex]) {
      return; // Already preloaded or image doesn't exist
    }

    const image = images.value[imageIndex];
    const img = new Image();
    img.onload = () => {
      preloadedImages.value.add(imageIndex);
    };
    img.onerror = () => {
      console.error(`Failed to preload image ${imageIndex}: ${image.filename}`);
    };
    // Use convertFileSrc for local file paths, fallback to HTTP URL
    img.src = image.file_path ? convertFileSrc(image.file_path) : `${API_BASE}${image.url}`;
  };

  const preloadImagesAhead = (fromIndex: number): void => {
    for (let i = 1; i <= preloadAheadCount; i++) {
      const targetIndex = fromIndex + i;
      if (targetIndex < images.value.length) {
        preloadImage(targetIndex);
      }
    }
  };

  const fetchImages = async (lastImage?: string): Promise<void> => {
    if (isLoading.value) return;
    
    isLoading.value = true;
    error.value = null;

    try {
      const params = new URLSearchParams({
        count: IMAGES_PER_BATCH.toString(),
        ordering: currentOrdering.value
      });

      if (lastImage) {
        params.append('last_image', lastImage);
      }

      const response = await fetch(`${API_BASE}/images?${params}`);
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      const data: ImagesResponse = await response.json();
      
      if ('error' in data) {
        throw new Error(String(data.error));
      }

      // If this is a fresh load (no lastImage), replace all images
      if (!lastImage) {
        images.value = data.images;
        currentIndex.value = 0;
        preloadedImages.value.clear(); // Clear preload cache
        // Preload images ahead from the current position
        preloadImagesAhead(0);
      } else {
        // Append new images for pagination
        images.value.push(...data.images);
        // Preload newly loaded images if they're in the ahead range
        const startPreloadFrom = Math.max(0, currentIndex.value);
        preloadImagesAhead(startPreloadFrom);
      }

      totalCount.value = data.total_count;
      
    } catch (err) {
      console.error('Error fetching images:', err);
      error.value = err instanceof Error ? err.message : 'Failed to load images';
    } finally {
      isLoading.value = false;
    }
  };

  const nextImage = async (): Promise<void> => {
    if (images.value.length === 0) return;

    const nextIndex = currentIndex.value + 1;

    // Check if we need to load more images before we run out
    // Load next batch when we're within preloadAheadCount images of the end
    const loadTriggerDistance = Math.max(preloadAheadCount, 2); 
    if (nextIndex >= images.value.length - loadTriggerDistance && 
        images.value.length < totalCount.value && 
        !isLoading.value) {
      const lastImage = images.value[images.value.length - 1]?.filename;
      await fetchImages(lastImage);
    }

    if (nextIndex < images.value.length) {
      currentIndex.value = nextIndex;
      // Preload images ahead from the new current position
      preloadImagesAhead(nextIndex);
    } else if (images.value.length >= totalCount.value) {
      // Loop back to beginning only if we have all images
      currentIndex.value = 0;
      preloadImagesAhead(0);
    }
    // If we don't have more images and haven't loaded all, stay on current image
  };

  const previousImage = (): void => {
    if (images.value.length === 0) return;

    const prevIndex = currentIndex.value - 1;
    if (prevIndex >= 0) {
      currentIndex.value = prevIndex;
      // Preload images ahead from the new current position
      preloadImagesAhead(prevIndex);
    } else {
      // Loop to end
      currentIndex.value = images.value.length - 1;
      preloadImagesAhead(images.value.length - 1);
    }
  };

  const startSlideshow = (): void => {
    if (slideInterval) {
      clearInterval(slideInterval);
    }

    slideInterval = window.setInterval(() => {
      if (!isPaused.value) {
        nextImage();
      }
    }, SLIDE_INTERVAL);
  };

  const stopSlideshow = (): void => {
    if (slideInterval) {
      clearInterval(slideInterval);
      slideInterval = null;
    }
  };

  const togglePause = (): void => {
    isPaused.value = !isPaused.value;
    
    if (isPaused.value) {
      stopSlideshow();
    } else {
      startSlideshow();
    }
  };

  const findImageIndex = (filename: string): number => {
    return images.value.findIndex(image => image.filename === filename);
  };

  const restoreLastImagePosition = async (): Promise<void> => {
    const lastImageName = cookieUtils.getLastImage();
    if (!lastImageName || images.value.length === 0) return;

    const savedIndex = findImageIndex(lastImageName);
    if (savedIndex !== -1) {
      currentIndex.value = savedIndex;
    }
  };

  const changeOrdering = async (newOrdering: OrderingMode): Promise<void> => {
    if (newOrdering === currentOrdering.value) return;

    currentOrdering.value = newOrdering;
    
    // Reload images with new ordering
    images.value = [];
    currentIndex.value = 0;
    preloadedImages.value.clear(); // Clear preload cache
    await fetchImages();
  };

  const loadInitialImages = async (): Promise<void> => {
    await fetchImages();
    if (images.value.length > 0) {
      await restoreLastImagePosition();
      startSlideshow();
    }
  };

  // Watch for current image changes and save to cookie
  watch(
    () => currentIndex.value,
    () => {
      const currentImage = images.value[currentIndex.value];
      if (currentImage) {
        cookieUtils.saveLastImage(currentImage.filename);
      }
    }
  );

  onMounted(() => {
    loadInitialImages();
  });

  onUnmounted(() => {
    stopSlideshow();
  });

  return {
    // State
    images,
    currentIndex,
    isPaused,
    currentOrdering,
    totalCount,
    isLoading,
    error,
    preloadedImages,
    
    // Configuration
    preloadAheadCount,
    
    // Actions
    nextImage,
    previousImage,
    togglePause,
    changeOrdering,
    fetchImages
  };
}
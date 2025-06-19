import { ref, onMounted, onUnmounted, watch } from 'vue';
import type { Image, ImagesResponse, OrderingMode } from '../types';
import { cookieUtils } from '../utils/cookies';

const API_BASE = 'http://localhost:8080';
const SLIDE_INTERVAL = 15000; // 15 seconds
const IMAGES_PER_BATCH = 10;

export function usePhotoFrame() {
  const images = ref<Image[]>([]);
  const currentIndex = ref(0);
  const isPaused = ref(false);
  const currentOrdering = ref<OrderingMode>('date_asc');
  const totalCount = ref(0);
  const isLoading = ref(false);
  const error = ref<string | null>(null);

  let slideInterval: number | null = null;

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
        console.log(`Loaded initial batch: ${data.images.length} images`);
      } else {
        // Append new images for pagination
        images.value.push(...data.images);
        console.log(`Loaded next batch: ${data.images.length} new images (total: ${images.value.length})`);
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

    // Check if we're approaching the end and need to load more images
    // Load next batch when we're on the second-to-last image
    if (nextIndex >= images.value.length - 1 && images.value.length < totalCount.value && !isLoading.value) {
      console.log(`Approaching end of current batch (${nextIndex + 1}/${images.value.length}), loading next batch...`);
      const lastImage = images.value[images.value.length - 1]?.filename;
      await fetchImages(lastImage);
    }

    if (nextIndex < images.value.length) {
      currentIndex.value = nextIndex;
    } else if (images.value.length >= totalCount.value) {
      // Loop back to beginning only if we have all images
      currentIndex.value = 0;
    }
    // If we don't have more images and haven't loaded all, stay on current image
  };

  const previousImage = (): void => {
    if (images.value.length === 0) return;

    const prevIndex = currentIndex.value - 1;
    if (prevIndex >= 0) {
      currentIndex.value = prevIndex;
    } else {
      // Loop to end
      currentIndex.value = images.value.length - 1;
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
      console.log(`Restored position to image: ${lastImageName} (index: ${savedIndex})`);
    } else {
      console.log(`Last image "${lastImageName}" not found in current batch, keeping current position`);
    }
  };

  const changeOrdering = async (newOrdering: OrderingMode): Promise<void> => {
    if (newOrdering === currentOrdering.value) return;

    currentOrdering.value = newOrdering;
    
    // Reload images with new ordering
    images.value = [];
    currentIndex.value = 0;
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
    
    // Actions
    nextImage,
    previousImage,
    togglePause,
    changeOrdering,
    fetchImages
  };
}
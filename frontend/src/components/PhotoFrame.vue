<template>
  <div class="photo-frame" @keydown="handleKeydown" tabindex="0">
    <div class="image-container">
      <!-- Loading state -->
      <div v-if="isLoading && images.length === 0" class="loading">
        Loading images...
      </div>

      <!-- Error state -->
      <div v-else-if="error" class="error">
        {{ error }}
      </div>

      <!-- Image slides -->
      <div v-else-if="images.length > 0" class="slides" @click="handleImageClick" @touchend="handleTouchEnd">
        <div
          v-for="(image, index) in images"
          :key="image.filename"
          :class="['image-slide', { active: index === currentIndex }]"
        >
          <img
            :src="getImageUrl(image)"
            :alt="image.filename"
            @load="handleImageLoad"
            @error="handleImageError(index)"
            loading="lazy"
          />
        </div>
      </div>

      <!-- No images state -->
      <div v-else class="no-images">
        No images available
      </div>
    </div>

    <!-- Image info -->
    <div v-if="currentImage" class="image-info">
      <div class="image-name">{{ currentImage.filename }}</div>
      <div class="image-index">{{ currentIndex + 1 }} of {{ totalCount }}</div>
    </div>

    <!-- Controls -->
    <div class="controls">
      <button @click="togglePause" class="btn btn-outline-light me-3">
        <i :class="isPaused ? 'bi bi-play-fill' : 'bi bi-pause-fill'"></i>
        {{ isPaused ? 'Play' : 'Pause' }}
      </button>
      
      <div class="btn-group" role="group">
        <button
          @click="changeOrdering('name_asc')"
          :class="['btn', currentOrdering === 'name_asc' ? 'btn-light' : 'btn-outline-light']"
          title="Sort by name ascending"
        >
          <i class="bi bi-sort-alpha-down"></i>
          Name
        </button>
        <button
          @click="changeOrdering('name_desc')"
          :class="['btn', currentOrdering === 'name_desc' ? 'btn-light' : 'btn-outline-light']"
          title="Sort by name descending"
        >
          <i class="bi bi-sort-alpha-up"></i>
          Name
        </button>
      </div>

      <div class="btn-group ms-2" role="group">
        <button
          @click="changeOrdering('date_asc')"
          :class="['btn', currentOrdering === 'date_asc' ? 'btn-light' : 'btn-outline-light']"
          title="Sort by date ascending"
        >
          <i class="bi bi-sort-numeric-down"></i>
          Date
        </button>
        <button
          @click="changeOrdering('date_desc')"
          :class="['btn', currentOrdering === 'date_desc' ? 'btn-light' : 'btn-outline-light']"
          title="Sort by date descending"
        >
          <i class="bi bi-sort-numeric-up"></i>
          Date
        </button>
      </div>

      <button
        @click="changeOrdering('random')"
        :class="['btn', 'ms-2', currentOrdering === 'random' ? 'btn-light' : 'btn-outline-light']"
        title="Random order"
      >
        <i class="bi bi-shuffle"></i>
        Random
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { usePhotoFrame } from '../composables/usePhotoFrame';

const {
  images,
  currentIndex,
  isPaused,
  currentOrdering,
  totalCount,
  isLoading,
  error,
  nextImage,
  previousImage,
  togglePause,
  changeOrdering
} = usePhotoFrame();

const currentImage = computed(() => images.value[currentIndex.value]);

const handleKeydown = (event: KeyboardEvent) => {
  switch (event.key) {
    case ' ':
      event.preventDefault();
      togglePause();
      break;
    case 'ArrowLeft':
      previousImage();
      break;
    case 'ArrowRight':
      nextImage();
      break;
  }
};

const handleImageClick = () => {
  nextImage();
};

const handleTouchEnd = (event: TouchEvent) => {
  event.preventDefault();
  nextImage();
};

const handleImageLoad = () => {
  // Image loaded successfully - could add any success handling here
};

const handleImageError = (index: number) => {
  const image = images.value[index];
  const url = getImageUrl(image);
  console.error(`Failed to load image ${index}: ${image?.filename} from URL: ${url}`);
};

const getImageUrl = (image: any) => {
  // Use HTTP URL from backend (static file serving)
  return `http://localhost:8080${image.url}`;
};
</script>

<style scoped>
.photo-frame {
  width: 100vw;
  height: 100vh;
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  outline: none;
}

.image-container {
  width: 100%;
  height: 100%;
  position: relative;
  overflow: hidden;
}

.slides {
  width: 100%;
  height: 100%;
  position: relative;
}

.image-slide {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  opacity: 0;
  transition: opacity 1s ease-in-out;
  display: flex;
  align-items: center;
  justify-content: center;
}

.image-slide.active {
  opacity: 1;
}

.image-slide img {
  max-width: 100%;
  max-height: 100%;
  object-fit: contain;
}

.loading,
.error,
.no-images {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  font-size: 18px;
  text-align: center;
}

.error {
  color: #ff6b6b;
}

.loading,
.no-images {
  color: #ccc;
}

.image-info {
  position: absolute;
  top: 20px;
  right: 20px;
  background: rgba(0, 0, 0, 0.7);
  padding: 10px;
  border-radius: 5px;
  font-size: 14px;
  opacity: 0;
  transition: opacity 0.3s ease;
}

.photo-frame:hover .image-info {
  opacity: 1;
}

.controls {
  position: absolute;
  bottom: 20px;
  left: 50%;
  transform: translateX(-50%);
  display: flex;
  align-items: center;
  gap: 10px;
  background: rgba(0, 0, 0, 0.8);
  padding: 15px 20px;
  border-radius: 15px;
  opacity: 0;
  transition: opacity 0.3s ease;
  backdrop-filter: blur(10px);
}

.photo-frame:hover .controls {
  opacity: 1;
}


.controls .btn {
  font-size: 14px;
  padding: 8px 12px;
  border-radius: 8px;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  gap: 5px;
}

.controls .btn i {
  font-size: 16px;
}

.controls .btn-group .btn {
  border-radius: 0;
}

.controls .btn-group .btn:first-child {
  border-top-left-radius: 8px;
  border-bottom-left-radius: 8px;
}

.controls .btn-group .btn:last-child {
  border-top-right-radius: 8px;
  border-bottom-right-radius: 8px;
}
</style>
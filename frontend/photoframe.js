const API_BASE = 'http://localhost:8080';
const SLIDE_INTERVAL = 15000; // 15 seconds
const IMAGES_PER_BATCH = 10;

class PhotoFrame {
    constructor() {
        this.images = [];
        this.currentIndex = 0;
        this.isPaused = false;
        this.currentOrdering = 'name_asc';
        this.slideInterval = null;
        this.lastImageFilename = null;
        this.totalCount = 0;
        this.isLoading = false;

        this.initializeElements();
        this.setupEventListeners();
        this.loadInitialImages();
    }

    initializeElements() {
        this.imageContainer = document.getElementById('imageContainer');
        this.loadingEl = document.getElementById('loading');
        this.errorEl = document.getElementById('error');
        this.imageInfoEl = document.getElementById('imageInfo');
        this.imageNameEl = document.getElementById('imageName');
        this.imageIndexEl = document.getElementById('imageIndex');
        
        this.pauseBtn = document.getElementById('pauseBtn');
        this.nameAscBtn = document.getElementById('nameAscBtn');
        this.nameDescBtn = document.getElementById('nameDescBtn');
        this.dateAscBtn = document.getElementById('dateAscBtn');
        this.dateDescBtn = document.getElementById('dateDescBtn');
        this.randomBtn = document.getElementById('randomBtn');

        this.updateOrderingButtons();
    }

    setupEventListeners() {
        this.pauseBtn.addEventListener('click', () => this.togglePause());
        this.nameAscBtn.addEventListener('click', () => this.changeOrdering('name_asc'));
        this.nameDescBtn.addEventListener('click', () => this.changeOrdering('name_desc'));
        this.dateAscBtn.addEventListener('click', () => this.changeOrdering('date_asc'));
        this.dateDescBtn.addEventListener('click', () => this.changeOrdering('date_desc'));
        this.randomBtn.addEventListener('click', () => this.changeOrdering('random'));

        // Keyboard shortcuts
        document.addEventListener('keydown', (e) => {
            switch(e.key) {
                case ' ':
                    e.preventDefault();
                    this.togglePause();
                    break;
                case 'ArrowLeft':
                    this.previousImage();
                    break;
                case 'ArrowRight':
                    this.nextImage();
                    break;
            }
        });
    }

    async loadInitialImages() {
        await this.fetchImages();
        if (this.images.length > 0) {
            this.showImage(0);
            this.startSlideshow();
        }
    }

    async fetchImages(lastImage = null) {
        if (this.isLoading) return;
        
        this.isLoading = true;
        this.showLoading(true);

        try {
            const params = new URLSearchParams({
                count: IMAGES_PER_BATCH.toString(),
                ordering: this.currentOrdering
            });

            if (lastImage) {
                params.append('last_image', lastImage);
            }

            const response = await fetch(`${API_BASE}/images?${params}`);
            
            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }

            const data = await response.json();
            
            if (data.error) {
                throw new Error(data.error);
            }

            // If this is a fresh load (no lastImage), replace all images
            if (!lastImage) {
                this.images = data.images;
                this.currentIndex = 0;
            } else {
                // Append new images for pagination
                this.images.push(...data.images);
            }

            this.totalCount = data.total_count;
            this.showError(false);
            
        } catch (error) {
            console.error('Error fetching images:', error);
            this.showError(true, `Failed to load images: ${error.message}`);
        } finally {
            this.isLoading = false;
            this.showLoading(false);
        }
    }

    showImage(index) {
        if (!this.images[index]) return;

        const image = this.images[index];
        this.currentIndex = index;

        // Remove existing image slides
        const existingSlides = this.imageContainer.querySelectorAll('.image-slide');
        existingSlides.forEach(slide => slide.remove());

        // Create new image slide
        const slideDiv = document.createElement('div');
        slideDiv.className = 'image-slide active';
        
        const imgEl = document.createElement('img');
        imgEl.src = `data:${image.mime_type};base64,${image.data}`;
        imgEl.alt = image.filename;
        
        slideDiv.appendChild(imgEl);
        this.imageContainer.appendChild(slideDiv);

        // Update image info
        this.imageNameEl.textContent = image.filename;
        this.imageIndexEl.textContent = `${index + 1} of ${this.totalCount}`;
        this.imageInfoEl.style.display = 'block';

        console.log(`Showing image ${index + 1}/${this.images.length}: ${image.filename}`);
    }

    async nextImage() {
        if (this.images.length === 0) return;

        const nextIndex = this.currentIndex + 1;

        // Check if we need to load more images
        if (nextIndex >= this.images.length && this.images.length < this.totalCount) {
            const lastImage = this.images[this.images.length - 1]?.filename;
            await this.fetchImages(lastImage);
        }

        if (nextIndex < this.images.length) {
            this.showImage(nextIndex);
        } else {
            // Loop back to beginning
            this.showImage(0);
        }
    }

    previousImage() {
        if (this.images.length === 0) return;

        const prevIndex = this.currentIndex - 1;
        if (prevIndex >= 0) {
            this.showImage(prevIndex);
        } else {
            // Loop to end
            this.showImage(this.images.length - 1);
        }
    }

    startSlideshow() {
        if (this.slideInterval) {
            clearInterval(this.slideInterval);
        }

        this.slideInterval = setInterval(() => {
            if (!this.isPaused) {
                this.nextImage();
            }
        }, SLIDE_INTERVAL);
    }

    stopSlideshow() {
        if (this.slideInterval) {
            clearInterval(this.slideInterval);
            this.slideInterval = null;
        }
    }

    togglePause() {
        this.isPaused = !this.isPaused;
        this.pauseBtn.textContent = this.isPaused ? 'Play' : 'Pause';
        
        if (this.isPaused) {
            this.stopSlideshow();
        } else {
            this.startSlideshow();
        }
    }

    async changeOrdering(newOrdering) {
        if (newOrdering === this.currentOrdering) return;

        this.currentOrdering = newOrdering;
        this.updateOrderingButtons();
        
        // Reload images with new ordering
        this.images = [];
        this.currentIndex = 0;
        await this.fetchImages();
        
        if (this.images.length > 0) {
            this.showImage(0);
        }
    }

    updateOrderingButtons() {
        [this.nameAscBtn, this.nameDescBtn, this.dateAscBtn, this.dateDescBtn, this.randomBtn]
            .forEach(btn => btn.classList.remove('active'));

        switch(this.currentOrdering) {
            case 'name_asc': this.nameAscBtn.classList.add('active'); break;
            case 'name_desc': this.nameDescBtn.classList.add('active'); break;
            case 'date_asc': this.dateAscBtn.classList.add('active'); break;
            case 'date_desc': this.dateDescBtn.classList.add('active'); break;
            case 'random': this.randomBtn.classList.add('active'); break;
        }
    }

    showLoading(show) {
        this.loadingEl.style.display = show ? 'block' : 'none';
    }

    showError(show, message = '') {
        this.errorEl.style.display = show ? 'block' : 'none';
        if (show && message) {
            this.errorEl.textContent = message;
        }
    }
}

// Initialize the photo frame when the page loads
document.addEventListener('DOMContentLoaded', () => {
    new PhotoFrame();
});
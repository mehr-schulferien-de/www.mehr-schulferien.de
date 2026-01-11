// Navigation Module - Vanilla JavaScript replacement for Alpine.js
export default class Navigation {
  constructor() {
    this.mobileMenu = null;
    this.mobileMenuToggle = null;
    this.mobileMenuClose = null;
    this.dropdowns = [];
    this.activeDropdown = null;
    
    this.init();
  }

  init() {
    // Wait for DOM to be ready
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', () => this.setup());
    } else {
      this.setup();
    }
  }

  setup() {
    this.setupMobileMenu();
    this.setupDesktopDropdowns();
    this.setupYearTabs();
    this.setupDismissibleAlerts();
    this.setupToastNotifications();
  }

  // Mobile Menu Functionality
  setupMobileMenu() {
    this.mobileMenu = document.querySelector('[data-mobile-menu]');
    this.mobileMenuToggle = document.querySelector('[data-mobile-menu-toggle]');
    this.mobileMenuClose = document.querySelector('[data-mobile-menu-close]');

    if (this.mobileMenuToggle && this.mobileMenu) {
      this.mobileMenuToggle.addEventListener('click', (e) => {
        e.stopPropagation();
        this.openMobileMenu();
      });
    }

    if (this.mobileMenuClose && this.mobileMenu) {
      this.mobileMenuClose.addEventListener('click', () => {
        this.closeMobileMenu();
      });
    }

    // Close mobile menu when clicking outside
    if (this.mobileMenu) {
      document.addEventListener('click', (e) => {
        if (!this.mobileMenu.contains(e.target) && 
            !this.mobileMenuToggle?.contains(e.target) &&
            this.mobileMenu.classList.contains('active')) {
          this.closeMobileMenu();
        }
      });
    }
  }

  openMobileMenu() {
    if (this.mobileMenu) {
      this.mobileMenu.classList.remove('hidden');
      this.mobileMenu.classList.add('active');
      // Add transition classes for smooth animation
      requestAnimationFrame(() => {
        this.mobileMenu.classList.add('transition-opacity', 'duration-300', 'ease-in-out');
        this.mobileMenu.style.opacity = '1';
      });
    }
  }

  closeMobileMenu() {
    if (this.mobileMenu) {
      this.mobileMenu.style.opacity = '0';
      setTimeout(() => {
        this.mobileMenu.classList.add('hidden');
        this.mobileMenu.classList.remove('active');
        this.mobileMenu.style.opacity = '';
      }, 300);
    }
  }

  // Desktop Dropdown Functionality
  setupDesktopDropdowns() {
    const dropdownContainers = document.querySelectorAll('[data-dropdown-container]');
    
    dropdownContainers.forEach(container => {
      const trigger = container.querySelector('[data-dropdown-trigger]');
      const menu = container.querySelector('[data-dropdown-menu]');
      
      if (trigger && menu) {
        const dropdown = {
          container,
          trigger,
          menu,
          isOpen: false
        };
        
        this.dropdowns.push(dropdown);
        
        // Click to toggle dropdown
        trigger.addEventListener('click', (e) => {
          e.stopPropagation();
          this.toggleDropdown(dropdown);
        });
        
        // Update ARIA attributes
        trigger.setAttribute('aria-haspopup', 'true');
        trigger.setAttribute('aria-expanded', 'false');
      }
    });
    
    // Close dropdowns when clicking outside
    document.addEventListener('click', () => {
      this.closeAllDropdowns();
    });
    
    // Prevent dropdown clicks from closing the dropdown
    this.dropdowns.forEach(dropdown => {
      dropdown.menu.addEventListener('click', (e) => {
        e.stopPropagation();
      });
    });
  }

  toggleDropdown(dropdown) {
    if (dropdown.isOpen) {
      this.closeDropdown(dropdown);
    } else {
      // Close other dropdowns first
      this.dropdowns.forEach(d => {
        if (d !== dropdown && d.isOpen) {
          this.closeDropdown(d);
        }
      });
      this.openDropdown(dropdown);
    }
  }

  openDropdown(dropdown) {
    dropdown.isOpen = true;
    dropdown.menu.classList.remove('hidden');
    dropdown.trigger.setAttribute('aria-expanded', 'true');
    
    // Add transition for smooth animation
    requestAnimationFrame(() => {
      dropdown.menu.classList.add('opacity-100', 'visible');
      dropdown.menu.classList.remove('opacity-0', 'invisible');
    });
    
    this.activeDropdown = dropdown;
  }

  closeDropdown(dropdown) {
    dropdown.isOpen = false;
    dropdown.menu.classList.add('opacity-0', 'invisible');
    dropdown.menu.classList.remove('opacity-100', 'visible');
    dropdown.trigger.setAttribute('aria-expanded', 'false');
    
    // Hide after transition
    setTimeout(() => {
      if (!dropdown.isOpen) {
        dropdown.menu.classList.add('hidden');
      }
    }, 200);
    
    if (this.activeDropdown === dropdown) {
      this.activeDropdown = null;
    }
  }

  closeAllDropdowns() {
    this.dropdowns.forEach(dropdown => {
      if (dropdown.isOpen) {
        this.closeDropdown(dropdown);
      }
    });
  }

  // Year Tabs Functionality for navigation dropdowns
  setupYearTabs() {
    const tabContainers = document.querySelectorAll('[data-year-tabs]');

    tabContainers.forEach(container => {
      const tabs = container.querySelectorAll('[data-year-tab]');
      const contents = container.querySelectorAll('[data-year-content]');

      tabs.forEach(tab => {
        tab.addEventListener('click', (e) => {
          e.preventDefault();
          e.stopPropagation();

          const year = tab.dataset.yearTab;

          // Update tab styles
          tabs.forEach(t => {
            t.classList.remove('bg-blue-600', 'text-white');
            t.classList.add('text-gray-600', 'hover:text-gray-900', 'hover:bg-gray-100');
          });
          tab.classList.add('bg-blue-600', 'text-white');
          tab.classList.remove('text-gray-600', 'hover:text-gray-900', 'hover:bg-gray-100');

          // Show/hide content
          contents.forEach(content => {
            if (content.dataset.yearContent === year) {
              content.classList.remove('hidden');
            } else {
              content.classList.add('hidden');
            }
          });
        });
      });
    });
  }

  // Dismissible Alerts Functionality
  setupDismissibleAlerts() {
    const dismissButtons = document.querySelectorAll('[data-dismiss-alert]');
    
    dismissButtons.forEach(button => {
      button.addEventListener('click', () => {
        const alert = button.closest('[role="alert"], [role="banner"]');
        if (alert) {
          // Add fade out animation
          alert.style.transition = 'opacity 300ms ease-in-out';
          alert.style.opacity = '0';
          
          setTimeout(() => {
            alert.remove();
          }, 300);
        }
      });
    });
  }

  // Toast Notifications with Auto-dismiss
  setupToastNotifications() {
    const toasts = document.querySelectorAll('[data-toast]');
    
    toasts.forEach(toast => {
      const autoDismiss = parseInt(toast.dataset.autoDismiss || '5000', 10);
      const dismissButton = toast.querySelector('[data-dismiss-toast]');
      
      // Setup auto-dismiss
      if (autoDismiss > 0) {
        setTimeout(() => {
          this.dismissToast(toast);
        }, autoDismiss);
      }
      
      // Setup manual dismiss
      if (dismissButton) {
        dismissButton.addEventListener('click', () => {
          this.dismissToast(toast);
        });
      }
    });
  }

  dismissToast(toast) {
    // Fade out animation
    toast.style.transition = 'opacity 200ms ease-in-out, transform 200ms ease-in-out';
    toast.style.opacity = '0';
    toast.style.transform = 'translateX(100%)';
    
    setTimeout(() => {
      toast.remove();
    }, 200);
  }

  // Helper method to show a toast programmatically
  showToast(message, type = 'info', duration = 5000) {
    const toastContainer = document.querySelector('[data-toast-container]') || document.body;
    
    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    toast.setAttribute('data-toast', '');
    toast.setAttribute('data-auto-dismiss', duration.toString());
    toast.innerHTML = `
      <div class="toast-content">
        <span class="toast-message">${message}</span>
        <button type="button" data-dismiss-toast class="toast-close">
          <span class="sr-only">Close</span>
          ×
        </button>
      </div>
    `;
    
    toastContainer.appendChild(toast);
    
    // Setup the new toast
    const dismissButton = toast.querySelector('[data-dismiss-toast]');
    if (dismissButton) {
      dismissButton.addEventListener('click', () => {
        this.dismissToast(toast);
      });
    }
    
    // Auto-dismiss
    if (duration > 0) {
      setTimeout(() => {
        this.dismissToast(toast);
      }, duration);
    }
    
    // Trigger entrance animation
    requestAnimationFrame(() => {
      toast.style.opacity = '1';
      toast.style.transform = 'translateX(0)';
    });
    
    return toast;
  }
}

// Auto-initialize when imported
const navigation = new Navigation();
export { navigation };
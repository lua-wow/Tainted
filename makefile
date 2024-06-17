# Makefile to create a .zip archive of the repository

# Name of the zip file
ZIP_NAME := repository_archive.zip

# Default target
all: $(ZIP_NAME)

# Create the .zip archive
$(ZIP_NAME):
	@echo "Creating $(ZIP_NAME)..."
	@zip -r $(ZIP_NAME) . -x@exclude.lst
	@echo "$(ZIP_NAME) created."

# Clean target to remove the .zip file
clean:
	@echo "Cleaning up..."
	@rm -f $(ZIP_NAME)
	@echo "Cleaned."

# Exclude certain files from the zip (optional)
exclude:
	@echo ".git/*" > exclude.lst
	@echo "$(ZIP_NAME)" >> exclude.lst

# Add exclude.lst to the clean target
clean-all: clean
	@rm -f exclude.lst

.PHONY: all

#!/bin/bash

chmod +x scripts/constants.sh
source scripts/constants.sh


clean_build() {
	print_status "Cleaning build artifacts..."
    
	if [ -d "build" ]; then
		rm -rf build
		print_status "Removed build directory"
	fi
    
	if [ -f "run" ]; then
	        rm run
	        print_status "Removed run script"
	fi
    
	if [ -f "CMakeUserPresets.json" ]; then
		rm CMakeUserPresets.json
		print_status "Removed CMakeUserPresets.json"
	fi
    
	find . -name "conan_profile.tmp" -delete 2>/dev/null || true
    
    	print_status "Build cleanup completed"
}
# Initialize a variable to track if 'clean' is found


main() {
	print_status "C++ Conan Template Build"
	print_status "===================================="
	# Loop through all arguments
	local found_clean=false
	for arg in "$@"; do
    	# Check if the argument contains 'clean'
    		if [[ $arg == *"clean"* ]]; then
       			found_clean=true
        		break
    		fi
	done

	if $found_clean; then
		print_status "'clean' argument detected. Cleaning ./make files..."
		clean_build
		return 0
	else
		bash scripts/make_cpp.sh
		touch run
		chmod +x run
		echo "#!/bin/bash" > run
		echo "source scripts/constants.sh" > run
		echo "start build/$PROJECT_NAME.exe" >> run
	
		echo "Finished Making CPP project..."
		echo ""
		echo "1) Now you may execute ./run"
		echo "2) To remove these dependencies, run ./make clean"
	fi
}
main "$@" 

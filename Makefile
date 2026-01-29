.PHONY: push

push:
	@git add -A && \
	git commit --amend --no-edit --allow-empty > /dev/null 2>&1 && \
	git push --force > /dev/null 2>&1 && \
	echo "Pushed successfully." && \
	gh browse || \
	echo "Push failed."

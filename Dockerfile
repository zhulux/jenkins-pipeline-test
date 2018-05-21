FROM ubuntu

RUN /bin/bash -c echo "This is simple test case! "
ENV mycustomenv1="KaLa is Dog." \
    otherenv="God is Girl!"
CMD ["sleep 120"]

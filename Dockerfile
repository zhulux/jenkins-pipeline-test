FROM ubuntu

RUN /bin/bash -c echo "This is simple test case! " && apt-get update && \
    apt-get install -y netcat
# hello
WORKDIR /root
COPY web.sh /root
ENV mycustomenv1="KaLa is Dog." \
    otherenv="God is Girl!"
EXPOSE 80/tcp
CMD ["/bin/sh", "web.sh"]

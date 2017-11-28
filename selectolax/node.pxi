
cdef class Node:
    cdef myhtml_tree_node_t *node
    cdef HtmlParser parser

    cdef _init(self, myhtml_tree_node_t *node, HtmlParser parser):
        # custom init, because __cinit__ doesn't accept C types
        self.node = node
        # Keep reference to the selector object, so myhtml structures will not be garbage collected prematurely
        self.parser = parser

    @property
    def attributes(self):
        """Get all attributes that belong to the current node.

        Returns
        -------
        attributes: dictionary of all attributes.
            Note that the value of empty attributes is None.

        """
        cdef myhtml_tree_attr_t *attr = myhtml_node_attribute_first(self.node)
        attributes = dict()

        while attr:
            key = attr.key.data.decode('UTF-8')
            if attr.value.data:
                value = attr.value.data.decode('UTF-8')
            else:
                value = None
            attributes[key] = value

            attr = attr.next

        return attributes

    @property
    def text(self):
        """Returns the text of the node including the text of child nodes.

        Returns
        -------
        text : str

        """
        text = None
        cdef const char*c_text
        cdef myhtml_tree_node_t*child = self.node.child

        while child != NULL:
            if child.tag_id == 1:
                c_text = myhtml_node_text(child, NULL)
                if c_text != NULL:
                    if text is None:
                        text = ""
                    text += c_text.decode('utf-8')

            child = child.child
        return text

    @property
    def tag(self):
        """Return the name of the current tag (e.g. div, p, img).

        Returns
        -------
        text : str
        """
        cdef const char *c_text
        c_text = myhtml_tag_name_by_id(self.node.tree, self.node.tag_id, NULL)
        text = None
        if c_text:
            text = c_text.decode("utf-8")
        return text

    @property
    def child(self):
        """Returns the child of current node."""
        cdef Node node
        if self.node.child:
            node = Node()
            node._init(self.node.child, self.parser)
            return node
        return None

    @property
    def parent(self):
        """Returns the parent of current node."""
        cdef Node node
        if self.node.parent:
            node = Node()
            node._init(self.node.parent, self.parser)
            return node
        return None

    @property
    def html(self):
        """Returns html representation of current node including all its child nodes.

        Returns
        -------
        text : str
        """
        cdef mycore_string_raw_t c_str
        c_str.data = NULL
        c_str.length = 0
        c_str.size = 0

        cdef mystatus_t status
        status = myhtml_serialization(self.node, &c_str)

        if status == 0 and c_str.data:
            html = c_str.data.decode('utf-8')
            free(c_str.data)
            return html

        return None

    def css(self, str selector):
        return HtmlParser(self.html).css(selector)